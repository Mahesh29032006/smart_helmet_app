import 'package:flutter/material.dart';
import '../../../core/models/incident.dart';
import '../../../core/models/responder.dart';
import '../../../core/models/responder_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/severity_indicator.dart';
import '../../../core/widgets/status_badge.dart';

/// Ambulance operational dispatch card with route points and status lifecycle buttons.
class DispatchCard extends StatelessWidget {
  final Incident incident;
  final Responder? ambulance;
  final Responder? hospital;
  final ValueChanged<ResponderStatus> onStatusChange;
  final VoidCallback onNavigate;

  const DispatchCard({
    super.key,
    required this.incident,
    this.ambulance,
    this.hospital,
    required this.onStatusChange,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = ambulance?.status ?? ResponderStatus.dispatched;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Incident ID + Status Badge + Severity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.airport_shuttle, color: AppTheme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dispatch for ${incident.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                StatusBadge.fromResponderStatus(currentStatus),
              ],
            ),
            const SizedBox(height: 10),
            SeverityIndicator(severity: incident.severity, compact: true),
            const SizedBox(height: 14),

            // Pickup & Destination Route Visualizer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Pickup Row
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: AppTheme.dangerColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PICKUP LOCATION (INCIDENT SCENE)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              incident.location.address ?? 'Saheed Nagar, Bhubaneswar',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 16,
                        child: VerticalDivider(color: Colors.grey, thickness: 1.5),
                      ),
                    ),
                  ),
                  // Destination Row
                  Row(
                    children: [
                      const Icon(Icons.local_hospital, color: AppTheme.successColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESTINATION HOSPITAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              hospital?.name ?? 'City Trauma Centre & Multi-speciality',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ETA and Distance Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${ambulance?.distanceKm?.toStringAsFixed(1) ?? '1.2'} km away',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer, size: 16, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ~${ambulance?.etaMinutes?.toStringAsFixed(0) ?? '3'} min',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Responder Status Progression Buttons
            const Text(
              'Update Response Status:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildStatusButton('ACCEPT', ResponderStatus.dispatched, currentStatus),
                _buildStatusButton('EN ROUTE', ResponderStatus.enRoute, currentStatus),
                _buildStatusButton('ARRIVED', ResponderStatus.arrived, currentStatus),
                _buildStatusButton('TRANSPORTING', ResponderStatus.transporting, currentStatus),
                _buildStatusButton('DELIVERED', ResponderStatus.available, currentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    ResponderStatus status,
    ResponderStatus currentStatus,
  ) {
    final isSelected = currentStatus == status;

    if (isSelected) {
      return ElevatedButton(
        onPressed: () => onStatusChange(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    return OutlinedButton(
      onPressed: () => onStatusChange(status),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
