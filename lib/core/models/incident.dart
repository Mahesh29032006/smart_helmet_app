import 'location_data.dart';

/// Severity levels for detected incidents.
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case IncidentSeverity.low:
        return 'Low Severity';
      case IncidentSeverity.medium:
        return 'Moderate Severity';
      case IncidentSeverity.high:
        return 'High Severity';
      case IncidentSeverity.critical:
        return 'Critical Severity';
    }
  }
}

/// Status of the incident in the system.
enum IncidentStatus {
  open,
  dispatched,
  inProgress,
  resolved,
  cancelled,
  failed;

  String get displayName {
    switch (this) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.dispatched:
        return 'Dispatched';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.cancelled:
        return 'Cancelled';
      case IncidentStatus.failed:
        return 'Failed';
    }
  }
}

/// Represents an emergency incident (crash, collision, medical emergency).
class Incident {
  final String id;
  final DateTime timestamp;
  final LocationData location;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final double crashConfidence;
  final String? assignedResponderId;
  final String? assignedHospitalId;
  final double? etaMinutes;
  final double? distanceKm;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const Incident({
    required this.id,
    required this.timestamp,
    required this.location,
    this.severity = IncidentSeverity.high,
    this.status = IncidentStatus.open,
    this.crashConfidence = 1.0,
    this.assignedResponderId,
    this.assignedHospitalId,
    this.etaMinutes,
    this.distanceKm,
    this.notes,
    this.metadata,
  });

  Incident copyWith({
    String? id,
    DateTime? timestamp,
    LocationData? location,
    IncidentSeverity? severity,
    IncidentStatus? status,
    double? crashConfidence,
    String? assignedResponderId,
    String? assignedHospitalId,
    double? etaMinutes,
    double? distanceKm,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Incident(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      crashConfidence: crashConfidence ?? this.crashConfidence,
      assignedResponderId: assignedResponderId ?? this.assignedResponderId,
      assignedHospitalId: assignedHospitalId ?? this.assignedHospitalId,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'location': location.toMap(),
      'severity': severity.name,
      'status': status.name,
      'crashConfidence': crashConfidence,
      'assignedResponderId': assignedResponderId,
      'assignedHospitalId': assignedHospitalId,
      'etaMinutes': etaMinutes,
      'distanceKm': distanceKm,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] as String,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      location: LocationData.fromMap(map['location'] as Map<String, dynamic>),
      severity: IncidentSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => IncidentSeverity.high,
      ),
      status: IncidentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => IncidentStatus.open,
      ),
      crashConfidence: (map['crashConfidence'] as num?)?.toDouble() ?? 1.0,
      assignedResponderId: map['assignedResponderId'] as String?,
      assignedHospitalId: map['assignedHospitalId'] as String?,
      etaMinutes: (map['etaMinutes'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() =>
      'Incident(id: $id, severity: ${severity.name}, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Incident && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
