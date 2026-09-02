import 'sensor_data.dart';
import 'location_data.dart';

/// GPS fix quality from the hardware.
enum GpsFixState {
  /// Active fix — real coordinates from GPS module.
  real,

  /// The last known fix, but no new fix has arrived recently.
  stale,

  /// No GPS fix available.
  unavailable;

  bool get hasPosition => this == GpsFixState.real || this == GpsFixState.stale;
}

/// Helmet device connectivity status based on last-seen telemetry age.
enum DeviceConnectionStatus {
  /// Recent telemetry received.
  online,

  /// Telemetry older than the stale threshold (10 s).
  stale,

  /// No telemetry beyond the offline threshold (60 s).
  offline;

  String get displayLabel {
    switch (this) {
      case DeviceConnectionStatus.online: return 'ONLINE';
      case DeviceConnectionStatus.stale: return 'STALE';
      case DeviceConnectionStatus.offline: return 'OFFLINE';
    }
  }
}

/// Hardware emergency state strings from the ESP32.
class HardwareStates {
  static const String normal = 'NORMAL';
  static const String crashPending = 'CRASH_PENDING';
  static const String emergencyConfirmed = 'EMERGENCY_CONFIRMED';
  static const String cancelled = 'CANCELLED';
  static const String manualEmergency = 'MANUAL_EMERGENCY';
}

/// Extensions to create [SensorData] from the backend's sensor.update JSON.
///
/// Backend payload (sensor.update):
/// {
///   "deviceId": "helmet-01",
///   "timestamp": "...",
///   "accelerometerX": 0.655,  (ax)
///   "accelerometerY": -0.198, (ay)
///   "accelerometerZ": 0.666,  (az)
///   "gyroscopeX": 5.18,       (gx)
///   "gyroscopeY": -2.56,      (gy)
///   "gyroscopeZ": 3.35,       (gz)
///   "accelMag": 0.955,
///   "gyroMag": 6.68,
///   "speedKmph": 0.3
/// }
extension SensorDataHardware on SensorData {
  /// Parses the flat sensor.update payload emitted by the backend.
  static SensorData fromHardwareSensorEvent(Map<String, dynamic> map) {
    return SensorData(
      accelerometerX: (map['accelerometerX'] as num?)?.toDouble() ?? 0.0,
      accelerometerY: (map['accelerometerY'] as num?)?.toDouble() ?? 0.0,
      accelerometerZ: (map['accelerometerZ'] as num?)?.toDouble() ?? 0.0,
      gyroscopeX: (map['gyroscopeX'] as num?)?.toDouble() ?? 0.0,
      gyroscopeY: (map['gyroscopeY'] as num?)?.toDouble() ?? 0.0,
      gyroscopeZ: (map['gyroscopeZ'] as num?)?.toDouble() ?? 0.0,
      speedKmph: (map['speedKmph'] as num?)?.toDouble() ?? 0.0,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  /// Parses the ESP32 canonical telemetry body's imu object.
  /// imu: { ax, ay, az, gx, gy, gz, accelMag, gyroMag }
  static SensorData fromHardwareImuJson(
    Map<String, dynamic> imu,
    double speedKmph,
    String? timestamp,
  ) {
    return SensorData(
      accelerometerX: (imu['ax'] as num?)?.toDouble() ?? 0.0,
      accelerometerY: (imu['ay'] as num?)?.toDouble() ?? 0.0,
      accelerometerZ: (imu['az'] as num?)?.toDouble() ?? 0.0,
      gyroscopeX: (imu['gx'] as num?)?.toDouble() ?? 0.0,
      gyroscopeY: (imu['gy'] as num?)?.toDouble() ?? 0.0,
      gyroscopeZ: (imu['gz'] as num?)?.toDouble() ?? 0.0,
      speedKmph: speedKmph,
      timestamp: _parseTimestamp(timestamp),
    );
  }
}

/// Extensions to create [LocationData] from the backend's location.update JSON.
///
/// Backend payload (location.update):
/// {
///   "deviceId": "helmet-01",
///   "timestamp": "...",
///   "fix": true,
///   "latitude": 22.2527,
///   "longitude": 84.9138,
///   "altitude": 217.9,
///   "speedKmph": 0.3,
///   "satellites": 12
/// }
extension LocationDataHardware on LocationData {
  /// Returns null when fix=false (caller must handle unavailable GPS).
  static LocationData? fromHardwareLocationEvent(Map<String, dynamic> map) {
    final fix = map['fix'] as bool? ?? false;
    if (!fix) return null;

    final lat = (map['latitude'] as num?)?.toDouble();
    final lon = (map['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    return LocationData(
      latitude: lat,
      longitude: lon,
      accuracy: 5.0, // GPS module typical accuracy
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: _kmphToMs((map['speedKmph'] as num?)?.toDouble() ?? 0.0),
      heading: 0.0,
      timestamp: _parseTimestamp(map['timestamp']),
      // Never fabricate an address from raw GPS in real hardware mode
      address: null,
    );
  }

  /// GPS fix state from a hardware location payload.
  static GpsFixState fixStateFromMap(Map<String, dynamic> map) {
    final fix = map['fix'] as bool? ?? false;
    return fix ? GpsFixState.real : GpsFixState.unavailable;
  }

  /// Satellites count from a hardware location payload.
  static int satellitesFromMap(Map<String, dynamic> map) {
    return (map['satellites'] as num?)?.toInt() ?? 0;
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

DateTime _parseTimestamp(dynamic ts) {
  if (ts is String && ts.isNotEmpty) {
    try { return DateTime.parse(ts); } catch (_) {}
  }
  return DateTime.now();
}

double _kmphToMs(double kmph) => kmph / 3.6;
