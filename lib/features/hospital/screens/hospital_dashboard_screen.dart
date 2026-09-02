import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/incident.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../widgets/patient_card.dart';

/// Screen 6: Hospital / Emergency Department triage dashboard for incoming trauma patients.
class HospitalDashboardScreen extends ConsumerStatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  ConsumerState<HospitalDashboardScreen> createState() =>
      _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends ConsumerState<HospitalDashboardScreen> {
  final Map<String, String> _patientStages = {};

  @override
  void initState() {
    super.initState();
    // Trigger notification feedback
    FeedbackService.triggerEmergencyAlarm();
  }

  @override
  Widget build(BuildContext context) {
    final activeIncidentsAsync = ref.watch(activeIncidentsProvider);
    final ambulance = ref.watch(assignedResponderProvider);
    final hospital = ref.watch(assignedHospitalProvider);
    final currentIncident = ref.watch(currentIncidentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Emergency Department'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Notification Alert',
            onPressed: () {
              UiLogger.log('Hospital alert sound triggered');
              FeedbackService.triggerEmergencyAlarm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auditory alert chime activated in Trauma Bay.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/hospital'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trauma Bay Facility Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital?.name ?? 'City Trauma Centre & Multi-speciality',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Level-1 Comprehensive Emergency & Trauma Facility',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.successColor),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: AppTheme.successColor),
                            SizedBox(width: 4),
                            Text(
                              'OPEN & READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Capacity Metrics Cards
                  Row(
                    children: [
                      _buildCapacityTile('TRAUMA BEDS', '3 Available', '6 Total', AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      _buildCapacityTile('ICU BAYS', '4 Free', '10 Total', AppTheme.infoColor),
                      const SizedBox(width: 8),
                      _buildCapacityTile('SURGEONS', '2 On-Duty', 'Trauma Team', AppTheme.successColor),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Inbound Trauma Alert Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.local_hospital, color: AppTheme.dangerColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Incoming Trauma Patients',
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'REAL-TIME TELEMETRY',
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

            // Incoming Patients Stream List
            activeIncidentsAsync.when(
              loading: () => const LoadingIndicator(message: 'Syncing with dispatch gateway...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (activeList) {
                // Combine live active incident with historical active list
                final combined = <Incident>[];
                if (currentIncident != null) {
                  combined.add(currentIncident);
                }
                for (final inc in activeList) {
                  if (combined.every((x) => x.id != inc.id)) {
                    combined.add(inc);
                  }
                }

                if (combined.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.local_hospital_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'No incoming patients at this moment',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Trauma team standing by for automatic crash notifications.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: combined.map((incident) {
                    final stage = _patientStages[incident.id] ?? 'BED_PREPARING';
                    return PatientCard(
                      incident: incident,
                      ambulance: ambulance,
                      hospitalStage: stage,
                      onStageChanged: (newStage) {
                        UiLogger.log('Hospital changed stage of ${incident.id} to $newStage');
                        setState(() {
                          _patientStages[incident.id] = newStage;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated ${incident.id} triage status: $newStage'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityTile(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
