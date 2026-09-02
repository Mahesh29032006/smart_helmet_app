import 'package:flutter/material.dart';
import '../models/responder.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Reusable responder unit card widget.
class ResponderCard extends StatelessWidget {
  final Responder responder;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;

  const ResponderCard({
    super.key,
    required this.responder,
    this.onTap,
    this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHospital = responder.type == ResponderType.hospital;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHospital
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isHospital
                          ? AppTheme.successLight
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isHospital ? Icons.local_hospital : Icons.airport_shuttle,
                      color: isHospital
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          responder.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (responder.vehicleNumber != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Plate: ${responder.vehicleNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge.fromResponderStatus(responder.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (responder.distanceKm != null)
                    _buildMetric(
                      Icons.near_me,
                      '${responder.distanceKm!.toStringAsFixed(1)} km',
                      'Distance',
                    ),
                  if (responder.etaMinutes != null)
                    _buildMetric(
                      Icons.timer,
                      '~${responder.etaMinutes!.toStringAsFixed(0)} min',
                      'ETA',
                    ),
                  _buildMetric(
                    Icons.star,
                    responder.rating.toStringAsFixed(1),
                    'Rating',
                  ),
                  if (responder.phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppTheme.successColor),
                      tooltip: 'Call ${responder.phone}',
                      onPressed: onCallTap ??
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling ${responder.name}: ${responder.phone}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
