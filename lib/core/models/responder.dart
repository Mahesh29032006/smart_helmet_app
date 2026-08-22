import 'location_data.dart';
import 'responder_status.dart';

/// Types of emergency response units.
enum ResponderType {
  ambulance,
  hospital,
  police,
  fire;

  String get displayName {
    switch (this) {
      case ResponderType.ambulance:
        return 'Ambulance';
      case ResponderType.hospital:
        return 'Hospital / Trauma Center';
      case ResponderType.police:
        return 'Police';
      case ResponderType.fire:
        return 'Fire & Rescue';
    }
  }
}

/// Represents an emergency responder or facility.
class Responder {
  final String id;
  final String name;
  final ResponderType type;
  final ResponderStatus status;
  final LocationData location;
  final String phone;
  final String? vehicleNumber;
  final bool traumaCapability;
  final double rating;
  final double? distanceKm;
  final double? etaMinutes;
  final String? assignedIncidentId;

  const Responder({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.location,
    required this.phone,
    this.vehicleNumber,
    this.traumaCapability = false,
    this.rating = 4.8,
    this.distanceKm,
    this.etaMinutes,
    this.assignedIncidentId,
  });

  Responder copyWith({
    String? id,
    String? name,
    ResponderType? type,
    ResponderStatus? status,
    LocationData? location,
    String? phone,
    String? vehicleNumber,
    bool? traumaCapability,
    double? rating,
    double? distanceKm,
    double? etaMinutes,
    String? assignedIncidentId,
  }) {
    return Responder(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      traumaCapability: traumaCapability ?? this.traumaCapability,
      rating: rating ?? this.rating,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      assignedIncidentId: assignedIncidentId ?? this.assignedIncidentId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'location': location.toMap(),
      'phone': phone,
      'vehicleNumber': vehicleNumber,
      'traumaCapability': traumaCapability,
      'rating': rating,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'assignedIncidentId': assignedIncidentId,
    };
  }

  factory Responder.fromMap(Map<String, dynamic> map) {
    return Responder(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ResponderType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ResponderType.ambulance,
      ),
      status: ResponderStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ResponderStatus.available,
      ),
      location: LocationData.fromMap(map['location'] as Map<String, dynamic>),
      phone: map['phone'] as String? ?? '',
      vehicleNumber: map['vehicleNumber'] as String?,
      traumaCapability: map['traumaCapability'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      etaMinutes: (map['etaMinutes'] as num?)?.toDouble(),
      assignedIncidentId: map['assignedIncidentId'] as String?,
    );
  }

  @override
  String toString() =>
      'Responder(id: $id, name: $name, type: ${type.name}, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Responder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
