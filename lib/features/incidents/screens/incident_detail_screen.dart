import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/incident.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/map_with_markers.dart';
import '../../../core/widgets/responder_card.dart';
import '../../../core/widgets/severity_indicator.dart';
import '../../../core/widgets/status_badge.dart';

/// Screen 3: Detailed Incident View with telemetry evidence, map, timeline, and actions.
class IncidentDetailScreen extends ConsumerWidget {
  final String id;

  const IncidentDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsListProvider);
    final dispatchService = ref.watch(dispatchServiceProvider);
    final currentLiveIncident = ref.watch(currentIncidentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Incident $id'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/incidents');
            }
          },
        ),
      ),
      body: incidentsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading incident details...'),
        error: (err, _) => Center(child: Text('Error loading incident: $err')),
        data: (incidents) {
          final incident = (currentLiveIncident != null && currentLiveIncident.id == id)
              ? currentLiveIncident
              : incidents.firstWhere(
                  (inc) => inc.id == id,
                  orElse: () => Incident(
                    id: id,
                    timestamp: DateTime.now(),
                    location: ref.watch(currentLocationDataProvider),
                    severity: IncidentSeverity.critical,
                    status: IncidentStatus.open,
                    crashConfidence: 0.95,
                    notes: 'Active live detected emergency',
                  ),
                );

          final respondersAsync = ref.watch(incidentRespondersProvider(id));
          final assignedResponder = respondersAsync.asData?.value.ambulance ??
              (currentLiveIncident?.id == id ? ref.watch(assignedResponderProvider) : null);
          final assignedHospital = respondersAsync.asData?.value.hospital ??
              (currentLiveIncident?.id == id ? ref.watch(assignedHospitalProvider) : null);
          final dateFormat = DateFormat('MMMM d, yyyy • HH:mm:ss');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              incident.id,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            StatusBadge.fromIncidentStatus(incident.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SeverityIndicator(severity: incident.severity),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(incident.crashConfidence * 100).toStringAsFixed(0)}% Confidence',
                                style: const TextStyle(
                                  color: AppTheme.dangerColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              dateFormat.format(incident.timestamp),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Location & Scene Map Preview Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: AppTheme.dangerColor),
                            SizedBox(width: 8),
                            Text(
                              'Incident Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          incident.location.address ?? 'Saheed Nagar, Bhubaneswar',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Coordinates: ${incident.location.latitude.toStringAsFixed(4)}, ${incident.location.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 180,
                            child: MapWithMarkers(
                              incidentLocation: incident.location,
                              ambulance: assignedResponder,
                              hospitals: assignedHospital != null ? [assignedHospital] : const [],
                              showPolyline: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sensor Evidence Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.query_stats, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Sensor Evidence & Telemetry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEvidenceTile(
                                'Peak G-Force',
                                '${(incident.metadata?['peakGForce'] as num? ?? 4.8).toStringAsFixed(1)} G',
                                Icons.compress,
                                AppTheme.dangerColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildEvidenceTile(
                                'Peak Rotation',
                                '${(incident.metadata?['peakAngularVelocity'] as num? ?? 3.5).toStringAsFixed(1)} rad/s',
                                Icons.sync,
                                AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                        if (incident.notes != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              incident.notes!,
                              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Assigned Responder & Hospital
                if (assignedResponder != null) ...[
                  const Text(
                    'Assigned Emergency Unit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ResponderCard(
                    responder: assignedResponder,
                    onCallTap: () {
                      UiLogger.log('User called responder ${assignedResponder.name}');
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                if (assignedHospital != null) ...[
                  const Text(
                    'Designated Trauma Facility',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ResponderCard(
                    responder: assignedHospital,
                    onCallTap: () {
                      UiLogger.log('User called hospital ${assignedHospital.name}');
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Lifecycle Timeline Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timeline, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Incident Timeline & Audit Trail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTimelineStep(
                          '1. Crash Anomaly Detected',
                          'Sensors registered >4.0G impact delta',
                          isComplete: true,
                        ),
                        _buildTimelineStep(
                          '2. Countdown & SOS Confirmation',
                          'User SOS auto-confirmed via countdown expiry',
                          isComplete: true,
                        ),
                        _buildTimelineStep(
                          '3. Emergency Dispatch & Unit Assignment',
                          incident.assignedResponderId != null
                              ? 'Assigned unit: ${incident.assignedResponderId}'
                              : 'Dispatched to nearest ALS unit',
                          isComplete: incident.status != IncidentStatus.open,
                        ),
                        _buildTimelineStep(
                          '4. Hospital Pre-notification',
                          'Trauma bay reserved at City Trauma Centre',
                          isComplete: incident.status == IncidentStatus.inProgress ||
                              incident.status == IncidentStatus.resolved,
                        ),
                        _buildTimelineStep(
                          '5. Patient Handover & Resolution',
                          incident.status == IncidentStatus.resolved
                              ? 'Incident resolved successfully'
                              : 'Pending final hospital delivery',
                          isComplete: incident.status == IncidentStatus.resolved,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Interactive Action Buttons
                Row(
                  children: [
                    if (incident.status != IncidentStatus.dispatched &&
                        incident.status != IncidentStatus.inProgress &&
                        incident.status != IncidentStatus.resolved)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            UiLogger.log('User dispatched emergency response for ${incident.id}');
                            await dispatchService.startDispatch(incident);
                            ref.invalidate(incidentsListProvider);
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Dispatch Units'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (incident.status == IncidentStatus.dispatched ||
                        incident.status == IncidentStatus.inProgress) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            UiLogger.log('User marked incident ${incident.id} as resolved');
                            await dispatchService.completeDispatch(incident.id);
                            ref.invalidate(incidentsListProvider);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Resolve Incident'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          UiLogger.log('User cancelled incident ${incident.id}');
                          await dispatchService.cancelDispatch(incident.id);
                          ref.invalidate(incidentsListProvider);
                        },
                        icon: const Icon(Icons.cancel, color: AppTheme.dangerColor),
                        label: const Text('Cancel SOS', style: TextStyle(color: AppTheme.dangerColor)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.dangerColor),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEvidenceTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle, {
    required bool isComplete,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete ? AppTheme.successColor : Colors.grey.shade300,
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.circle,
                size: 12,
                color: isComplete ? Colors.white : Colors.grey.shade600,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isComplete ? AppTheme.successColor : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isComplete ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
