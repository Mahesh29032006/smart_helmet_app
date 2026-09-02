import 'package:flutter/material.dart';
import '../../../core/models/responder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_badge.dart';

/// Floating HUD card on top of the Map showing active dispatch progress and ETA.
class MapDispatchHUD extends StatelessWidget {
  final Responder? ambulance;
  final Responder? hospital;
  final VoidCallback? onRecenter;

  const MapDispatchHUD({
    super.key,
    this.ambulance,
    this.hospital,
    this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    if (ambulance == null && hospital == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ambulance?.name ?? 'Assigned Unit',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital != null
                          ? 'En route to: ${hospital!.name}'
                          : 'Responding to emergency scene',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (ambulance != null)
                  StatusBadge.fromResponderStatus(ambulance!.status),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${ambulance?.distanceKm?.toStringAsFixed(1) ?? '1.2'} km',
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
                if (onRecenter != null)
                  IconButton(
                    icon: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 20),
                    tooltip: 'Recenter Scene',
                    onPressed: onRecenter,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
