import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../theme/app_theme.dart';

/// Visual severity indicator badge with icons and distinct color hierarchy.
class SeverityIndicator extends StatelessWidget {
  final IncidentSeverity severity;
  final bool compact;

  const SeverityIndicator({
    super.key,
    required this.severity,
    this.compact = false,
  });

  Color get _color {
    switch (severity) {
      case IncidentSeverity.critical:
        return AppTheme.dangerColor;
      case IncidentSeverity.high:
        return const Color(0xFFE65100);
      case IncidentSeverity.medium:
        return AppTheme.warningColor;
      case IncidentSeverity.low:
        return const Color(0xFF1976D2);
    }
  }

  Color get _backgroundColor {
    switch (severity) {
      case IncidentSeverity.critical:
        return AppTheme.dangerLight;
      case IncidentSeverity.high:
        return const Color(0xFFFFE0B2);
      case IncidentSeverity.medium:
        return AppTheme.warningLight;
      case IncidentSeverity.low:
        return const Color(0xFFE3F2FD);
    }
  }

  IconData get _icon {
    switch (severity) {
      case IncidentSeverity.critical:
        return Icons.dangerous;
      case IncidentSeverity.high:
        return Icons.report_problem;
      case IncidentSeverity.medium:
        return Icons.warning_amber_rounded;
      case IncidentSeverity.low:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 13, color: _color),
            const SizedBox(width: 4),
            Text(
              severity.name.toUpperCase(),
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: 6),
          Text(
            '${severity.name.toUpperCase()} SEVERITY',
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
