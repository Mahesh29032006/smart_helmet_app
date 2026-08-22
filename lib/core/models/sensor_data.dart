import 'dart:math' as math;

/// Represents high-frequency inertial and motion sensor telemetry.
class SensorData {
  final double accelerometerX;
  final double accelerometerY;
  final double accelerometerZ;
  final double gyroscopeX;
  final double gyroscopeY;
  final double gyroscopeZ;
  final double speedKmph;
  final DateTime timestamp;

  const SensorData({
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    this.speedKmph = 0.0,
    required this.timestamp,
  });

  /// Total acceleration magnitude in m/s^2.
  double get totalAcceleration => math.sqrt(
        accelerometerX * accelerometerX +
        accelerometerY * accelerometerY +
        accelerometerZ * accelerometerZ,
      );

  /// Acceleration in G-force (1G ≈ 9.80665 m/s^2).
  double get gForce => totalAcceleration / 9.80665;

  /// Total angular velocity magnitude in rad/s.
  double get totalAngularVelocity => math.sqrt(
        gyroscopeX * gyroscopeX +
        gyroscopeY * gyroscopeY +
        gyroscopeZ * gyroscopeZ,
      );

  Map<String, dynamic> toMap() {
    return {
      'accelerometerX': accelerometerX,
      'accelerometerY': accelerometerY,
      'accelerometerZ': accelerometerZ,
      'gyroscopeX': gyroscopeX,
      'gyroscopeY': gyroscopeY,
      'gyroscopeZ': gyroscopeZ,
      'speedKmph': speedKmph,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      accelerometerX: (map['accelerometerX'] as num).toDouble(),
      accelerometerY: (map['accelerometerY'] as num).toDouble(),
      accelerometerZ: (map['accelerometerZ'] as num).toDouble(),
      gyroscopeX: (map['gyroscopeX'] as num).toDouble(),
      gyroscopeY: (map['gyroscopeY'] as num).toDouble(),
      gyroscopeZ: (map['gyroscopeZ'] as num).toDouble(),
      speedKmph: (map['speedKmph'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
