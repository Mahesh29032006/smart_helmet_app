import 'package:flutter/material.dart';
import '../../../core/models/incident.dart';
import '../../../core/models/responder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/severity_indicator.dart';
import '../../../core/widgets/status_badge.dart';

/// Patient triage card for the emergency department hospital portal.
class PatientCard extends StatelessWidget {
  final Incident incident;
  final Responder? ambulance;
  final String hospitalStage;
  final ValueChanged<String>? onStageChanged;

  const PatientCard({
    super.key,
    required this.incident,
    this.ambulance,
    this.hospitalStage = 'PREPARING',
    this.onStageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.dangerColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top ID + Severity + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.personal_injury, color: AppTheme.dangerColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Patient #${incident.id.replaceAll('inc-', '')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SeverityIndicator(severity: incident.severity, compact: true),
              ],
            ),
            const SizedBox(height: 12),

            // Inbound Status Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATED ARRIVAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: AppTheme.warningColor),
                          const SizedBox(width: 4),
                          Text(
                            '~${incident.etaMinutes?.toStringAsFixed(0) ?? '4'} Minutes',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'AMBULANCE UNIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ambulance?.name ?? 'OD-02-EM-1081 (ALS)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Scene Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    incident.location.address ?? 'Incident Scene Location',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Hospital Workflow Status & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STAGE: $hospitalStage',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                StatusBadge.fromIncidentStatus(incident.status),
              ],
            ),
            const SizedBox(height: 12),

            // Triage Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton('NOTIFY RECEIVED', 'RECEIVED'),
                _buildActionButton('BED PREPARING', 'BED_PREPARING'),
                _buildActionButton('TRAUMA BAY READY', 'READY'),
                _buildActionButton('PATIENT RECEIVED', 'PATIENT_RECEIVED', isPrimary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, String stageKey, {bool isPrimary = false}) {
    final isCurrent = hospitalStage == stageKey;

    if (isPrimary || isCurrent) {
      return ElevatedButton(
        onPressed: () => onStageChanged?.call(stageKey),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrent ? AppTheme.successColor : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    return OutlinedButton(
      onPressed: () => onStageChanged?.call(stageKey),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
