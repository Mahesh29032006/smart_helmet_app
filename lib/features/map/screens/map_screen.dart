import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/responder.dart';
import '../../../core/models/responder_status.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/map_with_markers.dart';
import '../widgets/map_marker.dart';

/// Screen 4: Real-time interactive emergency dispatch map.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentLocation = ref.watch(currentLocationDataProvider);
    final responder = ref.watch(assignedResponderProvider);
    final hospital = ref.watch(assignedHospitalProvider);
    final currentIncident = ref.watch(currentIncidentProvider);
    final dispatchStatusAsync = ref.watch(dispatchStatusProvider);
    final dispatchStatus =
        dispatchStatusAsync.asData?.value ?? ref.watch(dispatchServiceProvider).currentStatus;

    final defaultHospitals = hospital != null
        ? [hospital]
        : [
            Responder(
              id: 'hosp-01',
              name: 'City Trauma Centre & Multi-speciality',
              type: ResponderType.hospital,
              status: ResponderStatus.available,
              location: incidentLocation.copyWith(
                latitude: incidentLocation.latitude + 0.015,
                longitude: incidentLocation.longitude + 0.012,
                address: 'Master Canteen Square',
              ),
              phone: '+91-674-2500100',
              traumaCapability: true,
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Emergency Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Map Legend',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Map Layers & Legend',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildLegendItem(
                        Icons.warning_amber_rounded,
                        AppTheme.dangerColor,
                        'Incident Scene',
                        'Active crash location with radar signal',
                      ),
                      const SizedBox(height: 12),
                      _buildLegendItem(
                        Icons.directions_car,
                        AppTheme.primaryColor,
                        'Ambulance Unit (ALS/BLS)',
                        'Real-time GPS vehicle tracking',
                      ),
                      const SizedBox(height: 12),
                      _buildLegendItem(
                        Icons.local_hospital,
                        AppTheme.successColor,
                        'Trauma Center / Hospital',
                        'Designated emergency receiving center',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/map'),
      body: Stack(
        children: [
          // Full-screen Map Canvas with real-time reactive markers & polyline
          Positioned.fill(
            child: MapWithMarkers(
              incidentLocation: incidentLocation,
              ambulance: responder,
              hospitals: defaultHospitals,
              incident: currentIncident,
              showPolyline: true,
              onCenterTap: () {
                UiLogger.log('User recentered map');
              },
            ),
          ),

          // Top Floating Status HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapDispatchHUD(
              ambulance: responder,
              hospital: hospital,
              onRecenter: () {
                UiLogger.log('User pressed recenter on map HUD');
              },
            ),
          ),

          // Bottom Control Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE DISPATCH: ${dispatchStatus.name.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'GPS: ${incidentLocation.latitude.toStringAsFixed(4)}, ${incidentLocation.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
