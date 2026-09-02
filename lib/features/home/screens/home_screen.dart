import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/emergency_state.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/map_with_markers.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/live_sensor_widget.dart';
import '../widgets/system_status_widget.dart';

/// Screen 1: Home / Live Telemetry Monitor with emergency countdown overlay.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorData = ref.watch(currentSensorDataProvider);
    final emergencyStateAsync = ref.watch(emergencyStateProvider);
    final emergencyState =
        emergencyStateAsync.asData?.value ?? ref.watch(stateMachineServiceProvider).currentState;
    final countdownAsync = ref.watch(countdownProvider);
    final countdownSeconds =
        countdownAsync.asData?.value ?? ref.watch(stateMachineServiceProvider).countdownSeconds;
    final location = ref.watch(currentLocationDataProvider);
    final responder = ref.watch(assignedResponderProvider);
    final hospital = ref.watch(assignedHospitalProvider);
    final config = ref.watch(appConfigProvider);

    final showCountdown =
        emergencyState == EmergencyState.countdown || emergencyState == EmergencyState.crashDetected;

    final confidence = emergencyState.isActiveEmergency
        ? 0.98
        : ((sensorData?.gForce ?? 1.0) > 2.0 ? 0.65 : 0.05);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Monitor & Crash Telemetry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View Map',
            onPressed: () {
              UiLogger.log('User navigated to Map from Home');
              context.go('/map');
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Incidents',
            onPressed: () {
              UiLogger.log('User navigated to Incidents from Home');
              context.go('/incidents');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // System State & Confidence Card
                SystemStatusWidget(
                  emergencyState: emergencyState,
                  confidenceScore: confidence,
                  onTriggerCrash: config.useRealHardware
                      ? null // No simulator crash injection in real hardware mode
                      : () {
                          UiLogger.log('User manually triggered simulated crash');
                          ref.read(sensorSimulatorProvider).injectCrashEvent(
                                gForce: 4.8,
                                rollRadS: 3.5,
                              );
                        },
                  onReset: () {
                    UiLogger.log('User reset state machine');
                    ref.read(stateMachineServiceProvider).reset();
                  },
                ),

                // Real-time Sensor Values (Visible when showDebugInfo is enabled)
                if (config.showDebugInfo)
                  LiveSensorWidget(
                    sensorData: sensorData,
                  ),

                // GPS Location & Mini Map Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, color: AppTheme.dangerColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'GPS Live Position',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Real hardware / simulation source badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (config.useRealHardware ? AppTheme.successColor : AppTheme.warningColor)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (config.useRealHardware ? AppTheme.successColor : AppTheme.warningColor)
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    config.useRealHardware ? 'REAL HW' : 'SIMULATED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: config.useRealHardware ? AppTheme.successColor : AppTheme.warningColor,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => context.go('/map'),
                                  icon: const Icon(Icons.fullscreen, size: 18),
                                  label: const Text('Expand'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // GPS fix status row (only in real hardware mode)
                        if (config.useRealHardware) ...[
                          Row(
                            children: [
                              _buildGpsBadge(ref),
                              const SizedBox(width: 8),
                              Text(
                                'Alt: ${location.altitude.toStringAsFixed(0)} m  •  '
                                '${(location.speed * 3.6).toStringAsFixed(1)} km/h',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          location.address ?? (config.useRealHardware ? 'Waiting for GPS fix...' : 'Locating GPS satellites...'),
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.latitude != 0.0 || !config.useRealHardware
                              ? 'Coords: ${location.latitude.toStringAsFixed(4)}° N, ${location.longitude.toStringAsFixed(4)}° E'
                              : 'Coordinates: awaiting GPS fix',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini Map Preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 160,
                            child: MapWithMarkers(
                              incidentLocation: location,
                              ambulance: responder,
                              hospitals: hospital != null ? [hospital] : const [],
                              showPolyline: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Navigation Hub
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/hospital'),
                          icon: const Icon(Icons.local_hospital, size: 18),
                          label: const Text('Hospital Hub'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/ambulance'),
                          icon: const Icon(Icons.directions_car, size: 18),
                          label: const Text('Ambulance Hub'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Countdown Full-Screen Overlay
          if (showCountdown)
            Positioned.fill(
              child: CountdownOverlay(
                countdownSeconds: countdownSeconds,
                onCancel: () {
                  ref.read(stateMachineServiceProvider).cancelEmergency();
                },
                onConfirm: () {
                  ref.read(stateMachineServiceProvider).confirmEmergency();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGpsBadge(WidgetRef ref) {
    final latestLoc = ref.watch(realLatestLocationProvider);
    final hasFix = latestLoc != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (hasFix ? AppTheme.successColor : AppTheme.dangerColor).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (hasFix ? AppTheme.successColor : AppTheme.dangerColor).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        hasFix ? 'FIX ✓' : 'NO FIX ✗',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: hasFix ? AppTheme.successColor : AppTheme.dangerColor,
        ),
      ),
    );
  }
}
