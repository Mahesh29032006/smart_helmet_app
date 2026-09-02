import 'package:flutter/material.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/theme/app_theme.dart';

/// Real-time multi-axis sensor telemetry widget.
class LiveSensorWidget extends StatelessWidget {
  final SensorData? sensorData;
  final VoidCallback? onSimulateCrash;

  const LiveSensorWidget({
    super.key,
    this.sensorData,
    this.onSimulateCrash,
  });

  Color _gForceColor(double gForce) {
    if (gForce < 1.5) return AppTheme.successColor;
    if (gForce < 3.0) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }

  @override
  Widget build(BuildContext context) {
    final data = sensorData ??
        SensorData(
          accelerometerX: 0.0,
          accelerometerY: 9.8,
          accelerometerZ: 0.0,
          gyroscopeX: 0.0,
          gyroscopeY: 0.0,
          gyroscopeZ: 0.0,
          speedKmph: 52.4,
          timestamp: DateTime.now(),
        );

    final gForce = data.gForce;
    final angularVel = data.totalAngularVelocity;
    final speed = data.speedKmph;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.sensors, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Live IMU Telemetry',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: AppTheme.successColor, size: 8),
                      SizedBox(width: 4),
                      Text(
                        '10 Hz STREAM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'G-FORCE',
                    value: '${gForce.toStringAsFixed(2)} g',
                    color: _gForceColor(gForce),
                    icon: Icons.compress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'ANGULAR VEL',
                    value: '${angularVel.toStringAsFixed(2)} rad/s',
                    color: angularVel > 2.5 ? AppTheme.dangerColor : AppTheme.primaryColor,
                    icon: Icons.sync,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'VEHICLE SPEED',
                    value: '${speed.toStringAsFixed(0)} km/h',
                    color: AppTheme.infoColor,
                    icon: Icons.speed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Accelerometer 3-Axis breakdown
            const Text(
              '3-Axis Accelerometer (m/s²)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildAxisBar('X', data.accelerometerX, -20.0, 20.0, Colors.blue),
                const SizedBox(width: 8),
                _buildAxisBar('Y', data.accelerometerY, -20.0, 20.0, Colors.orange),
                const SizedBox(width: 8),
                _buildAxisBar('Z', data.accelerometerZ, -20.0, 20.0, Colors.teal),
              ],
            ),
            const SizedBox(height: 12),

            // Gyroscope 3-Axis breakdown
            const Text(
              '3-Axis Gyroscope (rad/s)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildAxisBar('Roll', data.gyroscopeX, -10.0, 10.0, Colors.purple),
                const SizedBox(width: 8),
                _buildAxisBar('Pitch', data.gyroscopeY, -10.0, 10.0, Colors.indigo),
                const SizedBox(width: 8),
                _buildAxisBar('Yaw', data.gyroscopeZ, -10.0, 10.0, Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
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

  Widget _buildAxisBar(
    String label,
    double value,
    double min,
    double max,
    Color color,
  ) {
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: normalized,
                minHeight: 4,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
