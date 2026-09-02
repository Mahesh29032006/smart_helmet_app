import 'package:flutter/material.dart';
import '../../../core/models/emergency_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_badge.dart';

/// Displays the overarching emergency response lifecycle state and confidence meter.
class SystemStatusWidget extends StatelessWidget {
  final EmergencyState emergencyState;
  final double confidenceScore;
  final VoidCallback? onTriggerCrash;
  final VoidCallback? onReset;

  const SystemStatusWidget({
    super.key,
    required this.emergencyState,
    this.confidenceScore = 0.0,
    this.onTriggerCrash,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = emergencyState.isActiveEmergency;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppTheme.dangerColor : AppTheme.dividerLight,
          width: isActive ? 2.0 : 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SYSTEM STATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                StatusBadge.fromEmergencyState(emergencyState),
              ],
            ),
            const SizedBox(height: 12),

            // Confidence Score Meter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crash Confidence Score',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(confidenceScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: confidenceScore > 0.8
                        ? AppTheme.dangerColor
                        : (confidenceScore > 0.5 ? AppTheme.warningColor : AppTheme.successColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidenceScore.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  confidenceScore > 0.8
                      ? AppTheme.dangerColor
                      : (confidenceScore > 0.5 ? AppTheme.warningColor : AppTheme.successColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTriggerCrash,
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: const Text('Simulate Crash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (emergencyState != EmergencyState.idle &&
                    emergencyState != EmergencyState.monitoring) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
