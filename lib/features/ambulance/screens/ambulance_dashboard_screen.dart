import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/map_with_markers.dart';
import '../widgets/dispatch_card.dart';

/// Screen 7: Ambulance in-vehicle emergency dispatch and transit console.
class AmbulanceDashboardScreen extends ConsumerWidget {
  const AmbulanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambulance = ref.watch(assignedResponderProvider);
    final hospital = ref.watch(assignedHospitalProvider);
    final currentIncident = ref.watch(currentIncidentProvider);
    final dispatchService = ref.watch(dispatchServiceProvider);
    final location = ref.watch(currentLocationDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Terminal (ALS-1081)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Fullscreen Map',
            onPressed: () {
              UiLogger.log('Ambulance navigated to fullscreen map');
              context.go('/map');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/ambulance'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Status & Telemetry Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.airport_shuttle,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ambulance?.name ?? 'Ambulance A1 (Advance Life Support)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plate: ${ambulance?.vehicleNumber ?? 'OD-02-EM-1081'} • Unit: Mobile ALS Bay',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ambulance?.status.name.toUpperCase() ?? 'AVAILABLE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Active Dispatch Assignment
            if (currentIncident != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Assigned Emergency Dispatch',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRIORITY 1',
                        style: TextStyle(
                          color: AppTheme.dangerColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DispatchCard(
                incident: currentIncident,
                ambulance: ambulance,
                hospital: hospital,
                onStatusChange: (newStatus) async {
                  UiLogger.log('Ambulance changed status to ${newStatus.name}');
                  if (ambulance != null) {
                    await dispatchService.updateResponderStatus(ambulance.id, newStatus);
                  }
                },
                onNavigate: () {
                  UiLogger.log('Ambulance initiated turn-by-turn navigation');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting Turn-by-Turn GPS navigation to scene...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  context.go('/map');
                },
              ),
            ] else ...[
              // Standby Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 48, color: AppTheme.successColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Emergency Dispatched',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Unit OD-02-EM-1081 is currently on standby in Station Square.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            UiLogger.log('Ambulance simulated test crash trigger');
                            ref.read(sensorSimulatorProvider).injectCrashEvent();
                          },
                          icon: const Icon(Icons.warning_amber),
                          label: const Text('Simulate Emergency Dispatch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Active Route Map View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
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
                                Icon(Icons.route, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Live Navigation Radar',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'GPS LOCK: ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 200,
                          child: MapWithMarkers(
                            incidentLocation: currentIncident?.location ?? location,
                            ambulance: ambulance,
                            hospitals: hospital != null ? [hospital] : const [],
                            showPolyline: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
