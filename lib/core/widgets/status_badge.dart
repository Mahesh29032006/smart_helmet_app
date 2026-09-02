import 'package:flutter/material.dart';
import '../models/dispatch_status.dart';
import '../models/emergency_state.dart';
import '../models/incident.dart';
import '../models/responder_status.dart';
import '../theme/app_theme.dart';

/// Reusable status badge with contextual color themes and clean chip design.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.fontSize = 12.0,
  });

  factory StatusBadge.fromIncidentStatus(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return const StatusBadge(
          label: 'OPEN',
          backgroundColor: AppTheme.dangerLight,
          textColor: AppTheme.dangerColor,
          icon: Icons.error_outline,
        );
      case IncidentStatus.dispatched:
        return const StatusBadge(
          label: 'DISPATCHED',
          backgroundColor: Color(0xFFFFF3E0),
          textColor: AppTheme.warningColor,
          icon: Icons.send,
        );
      case IncidentStatus.inProgress:
        return const StatusBadge(
          label: 'IN PROGRESS',
          backgroundColor: AppTheme.primaryLight,
          textColor: AppTheme.primaryColor,
          icon: Icons.directions_car,
        );
      case IncidentStatus.resolved:
        return const StatusBadge(
          label: 'RESOLVED',
          backgroundColor: AppTheme.successLight,
          textColor: AppTheme.successColor,
          icon: Icons.check_circle_outline,
        );
      case IncidentStatus.cancelled:
        return const StatusBadge(
          label: 'CANCELLED',
          backgroundColor: Color(0xFFEEEEEE),
          textColor: Color(0xFF757575),
          icon: Icons.cancel_outlined,
        );
      case IncidentStatus.failed:
        return const StatusBadge(
          label: 'FAILED',
          backgroundColor: AppTheme.dangerLight,
          textColor: AppTheme.dangerColor,
          icon: Icons.highlight_off,
        );
    }
  }

  factory StatusBadge.fromEmergencyState(EmergencyState state) {
    switch (state) {
      case EmergencyState.idle:
      case EmergencyState.monitoring:
        return const StatusBadge(
          label: 'MONITORING',
          backgroundColor: AppTheme.successLight,
          textColor: AppTheme.successColor,
          icon: Icons.shield_outlined,
        );
      case EmergencyState.crashDetected:
        return const StatusBadge(
          label: 'SUSPECTED CRASH',
          backgroundColor: Color(0xFFFFF3E0),
          textColor: AppTheme.warningColor,
          icon: Icons.warning_amber_rounded,
        );
      case EmergencyState.countdown:
        return const StatusBadge(
          label: 'COUNTDOWN ACTIVE',
          backgroundColor: AppTheme.dangerLight,
          textColor: AppTheme.dangerColor,
          icon: Icons.timer,
        );
      case EmergencyState.confirmed:
        return const StatusBadge(
          label: 'CONFIRMED CRASH',
          backgroundColor: AppTheme.dangerLight,
          textColor: AppTheme.dangerColor,
          icon: Icons.emergency,
        );
      case EmergencyState.dispatched:
        return const StatusBadge(
          label: 'UNITS DISPATCHED',
          backgroundColor: AppTheme.primaryLight,
          textColor: AppTheme.primaryColor,
          icon: Icons.local_hospital,
        );
      case EmergencyState.cancelled:
        return const StatusBadge(
          label: 'CANCELLED',
          backgroundColor: Color(0xFFEEEEEE),
          textColor: Color(0xFF757575),
          icon: Icons.cancel_outlined,
        );
      case EmergencyState.resolved:
        return const StatusBadge(
          label: 'RESOLVED',
          backgroundColor: AppTheme.successLight,
          textColor: AppTheme.successColor,
          icon: Icons.check_circle_outline,
        );
    }
  }

  factory StatusBadge.fromDispatchStatus(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.idle:
        return const StatusBadge(
          label: 'STANDBY',
          backgroundColor: Color(0xFFECEFF1),
          textColor: Color(0xFF607D8B),
          icon: Icons.pause_circle_outline,
        );
      case DispatchStatus.searching:
        return const StatusBadge(
          label: 'SEARCHING UNITS',
          backgroundColor: Color(0xFFFFF3E0),
          textColor: AppTheme.warningColor,
          icon: Icons.radar,
        );
      case DispatchStatus.dispatched:
        return const StatusBadge(
          label: 'DISPATCHED',
          backgroundColor: AppTheme.primaryLight,
          textColor: AppTheme.primaryColor,
          icon: Icons.send,
        );
      case DispatchStatus.acknowledged:
        return const StatusBadge(
          label: 'ACCEPTED',
          backgroundColor: Color(0xFFE8EAF6),
          textColor: Color(0xFF3F51B5),
          icon: Icons.thumb_up_alt_outlined,
        );
      case DispatchStatus.enRoute:
        return const StatusBadge(
          label: 'EN ROUTE',
          backgroundColor: AppTheme.primaryLight,
          textColor: AppTheme.primaryColor,
          icon: Icons.directions_car,
        );
      case DispatchStatus.arrived:
        return const StatusBadge(
          label: 'ARRIVED AT SCENE',
          backgroundColor: Color(0xFFE0F2F1),
          textColor: AppTheme.infoColor,
          icon: Icons.location_on,
        );
      case DispatchStatus.transporting:
        return const StatusBadge(
          label: 'TRANSPORTING',
          backgroundColor: Color(0xFFEDE7F6),
          textColor: Color(0xFF673AB7),
          icon: Icons.local_hospital,
        );
      case DispatchStatus.delivered:
      case DispatchStatus.completed:
        return const StatusBadge(
          label: 'DELIVERED',
          backgroundColor: AppTheme.successLight,
          textColor: AppTheme.successColor,
          icon: Icons.check_circle,
        );
      case DispatchStatus.cancelled:
        return const StatusBadge(
          label: 'CANCELLED',
          backgroundColor: Color(0xFFEEEEEE),
          textColor: Color(0xFF757575),
          icon: Icons.cancel_outlined,
        );
      case DispatchStatus.failed:
        return const StatusBadge(
          label: 'DISPATCH FAILED',
          backgroundColor: AppTheme.dangerLight,
          textColor: AppTheme.dangerColor,
          icon: Icons.error_outline,
        );
    }
  }

  factory StatusBadge.fromResponderStatus(ResponderStatus status) {
    switch (status) {
      case ResponderStatus.available:
        return const StatusBadge(
          label: 'AVAILABLE',
          backgroundColor: AppTheme.successLight,
          textColor: AppTheme.successColor,
          icon: Icons.check_circle_outline,
        );
      case ResponderStatus.dispatched:
        return const StatusBadge(
          label: 'DISPATCHED',
          backgroundColor: Color(0xFFFFF3E0),
          textColor: AppTheme.warningColor,
          icon: Icons.notifications_active,
        );
      case ResponderStatus.enRoute:
        return const StatusBadge(
          label: 'EN ROUTE',
          backgroundColor: AppTheme.primaryLight,
          textColor: AppTheme.primaryColor,
          icon: Icons.directions_car,
        );
      case ResponderStatus.arrived:
        return const StatusBadge(
          label: 'AT SCENE',
          backgroundColor: Color(0xFFE0F2F1),
          textColor: AppTheme.infoColor,
          icon: Icons.location_on,
        );
      case ResponderStatus.transporting:
        return const StatusBadge(
          label: 'TRANSPORTING',
          backgroundColor: Color(0xFFEDE7F6),
          textColor: Color(0xFF673AB7),
          icon: Icons.local_hospital,
        );
      case ResponderStatus.unavailable:
        return const StatusBadge(
          label: 'UNAVAILABLE',
          backgroundColor: Color(0xFFEEEEEE),
          textColor: Color(0xFF757575),
          icon: Icons.block,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
