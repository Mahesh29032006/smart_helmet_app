import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../theme/app_theme.dart';

/// Interactive real-time emergency map widget rendered with animated markers and polylines.
class MapWithMarkers extends StatefulWidget {
  final LocationData? incidentLocation;
  final Responder? ambulance;
  final List<Responder> hospitals;
  final Incident? incident;
  final bool showPolyline;
  final VoidCallback? onCenterTap;

  const MapWithMarkers({
    super.key,
    this.incidentLocation,
    this.ambulance,
    this.hospitals = const [],
    this.incident,
    this.showPolyline = true,
    this.onCenterTap,
  });

  @override
  State<MapWithMarkers> createState() => _MapWithMarkersState();
}

class _MapWithMarkersState extends State<MapWithMarkers>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedMarkerTitle;
  String? _selectedMarkerSubtitle;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Bounding box calculations around incident
        final centerLat = widget.incidentLocation?.latitude ?? 20.2961;
        final centerLng = widget.incidentLocation?.longitude ?? 85.8245;

        // Conversion helper to map GPS coords to screen coordinates
        Offset toScreen(double lat, double lng) {
          // Span roughly 0.08 degrees in lat/long across map viewport
          const double span = 0.08;
          final dx = width / 2 + ((lng - centerLng) / span) * width;
          final dy = height / 2 - ((lat - centerLat) / span) * height;
          return Offset(dx.clamp(20.0, width - 20.0), dy.clamp(20.0, height - 20.0));
        }

        final incidentPos = widget.incidentLocation != null
            ? toScreen(widget.incidentLocation!.latitude, widget.incidentLocation!.longitude)
            : Offset(width / 2, height / 2);

        final ambulancePos = widget.ambulance != null
            ? toScreen(widget.ambulance!.location.latitude, widget.ambulance!.location.longitude)
            : null;

        return Stack(
          children: [
            // Map Grid Background / Radar Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MapCanvasPainter(
                      incidentPos: incidentPos,
                      ambulancePos: ambulancePos,
                      hospitalPositions: widget.hospitals
                          .map((h) => toScreen(h.location.latitude, h.location.longitude))
                          .toList(),
                      pulseValue: _pulseController.value,
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                      drawPolyline: widget.showPolyline,
                    ),
                  );
                },
              ),
            ),

            // Hospitals Markers
            for (final hosp in widget.hospitals) ...[
              Builder(
                builder: (context) {
                  final pos = toScreen(hosp.location.latitude, hosp.location.longitude);
                  return Positioned(
                    left: pos.dx - 18,
                    top: pos.dy - 18,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMarkerTitle = hosp.name;
                          _selectedMarkerSubtitle =
                              '${hosp.location.address ?? 'Hospital'} • Phone: ${hosp.phone}';
                        });
                      },
                      child: Tooltip(
                        message: hosp.name,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            // Incident Marker (Red pulsing)
            if (widget.incidentLocation != null)
              Positioned(
                left: incidentPos.dx - 22,
                top: incidentPos.dy - 22,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMarkerTitle = 'Emergency Incident Scene';
                      _selectedMarkerSubtitle =
                          widget.incidentLocation?.address ?? 'GPS: ${widget.incidentLocation?.latitude.toStringAsFixed(4)}, ${widget.incidentLocation?.longitude.toStringAsFixed(4)}';
                    });
                  },
                  child: Tooltip(
                    message: 'Emergency Incident',
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Ambulance Marker (Blue vehicle)
            if (ambulancePos != null && widget.ambulance != null)
              Positioned(
                left: ambulancePos.dx - 20,
                top: ambulancePos.dy - 20,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMarkerTitle = widget.ambulance!.name;
                      _selectedMarkerSubtitle =
                          'Status: ${widget.ambulance!.status.name.toUpperCase()} • ETA: ${widget.ambulance!.etaMinutes?.toStringAsFixed(1) ?? 'N/A'} min';
                    });
                  },
                  child: Tooltip(
                    message: widget.ambulance!.name,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),

            // Selected Marker Popup Callout
            if (_selectedMarkerTitle != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  elevation: 6,
                  color: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedMarkerTitle!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (_selectedMarkerSubtitle != null)
                                Text(
                                  _selectedMarkerSubtitle!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedMarkerTitle = null;
                              _selectedMarkerSubtitle = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final Offset incidentPos;
  final Offset? ambulancePos;
  final List<Offset> hospitalPositions;
  final double pulseValue;
  final bool isDarkMode;
  final bool drawPolyline;

  _MapCanvasPainter({
    required this.incidentPos,
    required this.ambulancePos,
    required this.hospitalPositions,
    required this.pulseValue,
    required this.isDarkMode,
    required this.drawPolyline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background terrain fill
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1B222C) : const Color(0xFFE8EEF5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid / Map streets lines
    final gridPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF263238) : const Color(0xFFD6DFE8)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Major roadway corridors
    final roadPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF37474F) : const Color(0xFFCBD5E1)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.65, size.height),
      roadPaint,
    );

    // Incident Pulsing Radar Wave
    final pulsePaint = Paint()
      ..color = AppTheme.dangerColor.withValues(alpha: (1.0 - pulseValue).clamp(0.0, 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(incidentPos, 20.0 + (pulseValue * 45.0), pulsePaint);

    final innerRadarPaint = Paint()
      ..color = AppTheme.dangerColor.withValues(alpha: (0.6 - pulseValue * 0.5).clamp(0.0, 0.3))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(incidentPos, 15.0 + (pulseValue * 30.0), innerRadarPaint);

    // Polyline route from Ambulance to Incident
    if (drawPolyline && ambulancePos != null) {
      final polylineGlow = Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: 0.4)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final polylinePaint = Paint()
        ..color = AppTheme.primaryColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw dashed/animated route line
      canvas.drawLine(ambulancePos!, incidentPos, polylineGlow);
      _drawDashedLine(canvas, ambulancePos!, incidentPos, polylinePaint);
    }

    // Polyline route from Incident to nearest Hospital
    if (drawPolyline && hospitalPositions.isNotEmpty) {
      final nearestHosp = hospitalPositions.first;
      final hospRoutePaint = Paint()
        ..color = AppTheme.successColor.withValues(alpha: 0.7)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, incidentPos, nearestHosp, hospRoutePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 5.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final double cosAngle = dx / distance;
    final double sinAngle = dy / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final double nextDist = math.min(currentDist + dashWidth, distance);
      canvas.drawLine(
        Offset(p1.dx + currentDist * cosAngle, p1.dy + currentDist * sinAngle),
        Offset(p1.dx + nextDist * cosAngle, p1.dy + nextDist * sinAngle),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.incidentPos != incidentPos ||
        oldDelegate.ambulancePos != ambulancePos ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
