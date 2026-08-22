import 'dart:math' as math;

/// Represents geographical coordinates and associated telemetry data.
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed; // in m/s
  final double heading; // in degrees (0-360)
  final DateTime timestamp;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy = 5.0,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.timestamp,
    this.address,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? address,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 5.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      address: map['address'] as String?,
    );
  }

  @override
  String toString() =>
      'LocationData(lat: $latitude, lon: $longitude, acc: ${accuracy}m, speed: ${speed}m/s)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Computes the great-circle distance between two points on Earth using the Haversine formula.
/// Returns distance in kilometers.
double calculateDistance(LocationData from, LocationData to) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(to.latitude - from.latitude);
  final double dLon = _degreesToRadians(to.longitude - from.longitude);

  final double lat1 = _degreesToRadians(from.latitude);
  final double lat2 = _degreesToRadians(to.latitude);

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) *
          math.sin(dLon / 2) *
          math.cos(lat1) *
          math.cos(lat2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Calculates Estimated Time of Arrival (ETA) in minutes between two locations.
///
/// [avgSpeedKmph] is the assumed average speed in km/h (default is 40.0 km/h for urban emergency response).
/// Includes an optional traffic/delay factor.
double calculateETA(
  LocationData from,
  LocationData to, {
  double avgSpeedKmph = 40.0,
  double trafficMultiplier = 1.0,
}) {
  final double distanceKm = calculateDistance(from, to);
  if (avgSpeedKmph <= 0) return 0.0;
  final double travelHours = (distanceKm / avgSpeedKmph) * trafficMultiplier;
  return travelHours * 60.0; // returns minutes
}

/// Interpolates a linear point between start and end coordinates based on a fractional factor (0.0 to 1.0).
LocationData interpolateLocation(
  LocationData start,
  LocationData end,
  double fraction, {
  DateTime? timestamp,
}) {
  final clampedFraction = fraction.clamp(0.0, 1.0);
  final lat = start.latitude + (end.latitude - start.latitude) * clampedFraction;
  final lon = start.longitude + (end.longitude - start.longitude) * clampedFraction;
  final alt = start.altitude + (end.altitude - start.altitude) * clampedFraction;
  final speed = start.speed + (end.speed - start.speed) * clampedFraction;

  return LocationData(
    latitude: lat,
    longitude: lon,
    altitude: alt,
    speed: speed,
    accuracy: start.accuracy,
    timestamp: timestamp ?? DateTime.now(),
  );
}

double _degreesToRadians(double degrees) {
  return degrees * (math.pi / 180.0);
}
