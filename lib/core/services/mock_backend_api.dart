import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/responder_status.dart';
import 'backend_api.dart';

/// In-memory mock backend API with sample emergency assets and Haversine sorting.
class MockBackendApiClient implements BackendApiClient {
  final Map<String, Incident> _incidents = {};
  final Map<String, Responder> _responders = {};

  MockBackendApiClient({
    List<Responder>? initialResponders,
    List<Incident>? initialIncidents,
  }) {
    if (initialResponders != null) {
      for (final r in initialResponders) {
        _responders[r.id] = r;
      }
    } else {
      _seedDefaultResponders();
    }

    if (initialIncidents != null) {
      for (final inc in initialIncidents) {
        _incidents[inc.id] = inc;
      }
    } else {
      _seedDefaultIncidents();
    }
  }

  void _seedDefaultResponders() {
    final now = DateTime.now();

    final defaultList = [
      // Closest Ambulance A1 (~0.8 km)
      Responder(
        id: 'amb-01',
        name: 'Ambulance A1 (Advance Life Support)',
        type: ResponderType.ambulance,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3015,
          longitude: 85.8290,
          timestamp: now,
          address: 'Station Square, Unit 3',
        ),
        phone: '+91-9876543210',
        vehicleNumber: 'OD-02-EM-1081',
        rating: 4.9,
      ),
      // Secondary Ambulance A2 (~3.2 km)
      Responder(
        id: 'amb-02',
        name: 'Ambulance A2 (Basic Life Support)',
        type: ResponderType.ambulance,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3220,
          longitude: 85.8110,
          timestamp: now,
          address: 'Jayadev Vihar',
        ),
        phone: '+91-9876543211',
        vehicleNumber: 'OD-02-EM-1082',
        rating: 4.7,
      ),
      // Far Ambulance A3 (~12 km)
      Responder(
        id: 'amb-03',
        name: 'Ambulance A3 (Rural Rapid Unit)',
        type: ResponderType.ambulance,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.1900,
          longitude: 85.7400,
          timestamp: now,
          address: 'Khurda Highway',
        ),
        phone: '+91-9876543212',
        vehicleNumber: 'OD-02-EM-1083',
        rating: 4.6,
      ),
      // Nearest Trauma Hospital H1 (~2.5 km)
      Responder(
        id: 'hosp-01',
        name: 'City Trauma Centre & Multi-speciality',
        type: ResponderType.hospital,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3120,
          longitude: 85.8390,
          timestamp: now,
          address: 'Master Canteen Square',
        ),
        phone: '+91-674-2500100',
        traumaCapability: true,
        rating: 4.95,
      ),
      // Secondary Hospital H2 (~5.0 km, no Level-1 trauma)
      Responder(
        id: 'hosp-02',
        name: 'Metro Community Clinic',
        type: ResponderType.hospital,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3400,
          longitude: 85.8000,
          timestamp: now,
          address: 'Patia Infocity',
        ),
        phone: '+91-674-2500200',
        traumaCapability: false,
        rating: 4.5,
      ),
    ];

    for (final r in defaultList) {
      _responders[r.id] = r;
    }
  }

  void _seedDefaultIncidents() {
    final now = DateTime.now();

    final defaultIncidents = [
      Incident(
        id: 'inc-101',
        timestamp: now.subtract(const Duration(minutes: 42)),
        location: LocationData(
          latitude: 20.2961,
          longitude: 85.8245,
          timestamp: now.subtract(const Duration(minutes: 42)),
          address: 'Janpath Rd, Saheed Nagar, Bhubaneswar',
        ),
        severity: IncidentSeverity.critical,
        status: IncidentStatus.resolved,
        crashConfidence: 0.98,
        assignedResponderId: 'amb-01',
        assignedHospitalId: 'hosp-01',
        distanceKm: 1.2,
        etaMinutes: 3.5,
        notes: 'High impact collision detected at 55 km/h. Responders delivered patient successfully.',
        metadata: {
          'peakGForce': 4.8,
          'peakAngularVelocity': 3.6,
          'trigger': 'Multi-signal crash trigger',
        },
      ),
      Incident(
        id: 'inc-102',
        timestamp: now.subtract(const Duration(minutes: 18)),
        location: LocationData(
          latitude: 20.3250,
          longitude: 85.8150,
          timestamp: now.subtract(const Duration(minutes: 18)),
          address: 'NH-16 Flyover, Jayadev Vihar, Bhubaneswar',
        ),
        severity: IncidentSeverity.high,
        status: IncidentStatus.inProgress,
        crashConfidence: 0.92,
        assignedResponderId: 'amb-02',
        assignedHospitalId: 'hosp-01',
        distanceKm: 2.8,
        etaMinutes: 6.0,
        notes: 'Side impact rollover detected. Ambulance en route with trauma team.',
        metadata: {
          'peakGForce': 3.9,
          'peakAngularVelocity': 2.9,
          'trigger': 'High G-Force deceleration',
        },
      ),
      Incident(
        id: 'inc-103',
        timestamp: now.subtract(const Duration(minutes: 5)),
        location: LocationData(
          latitude: 20.3080,
          longitude: 85.8320,
          timestamp: now.subtract(const Duration(minutes: 5)),
          address: 'Station Square, Master Canteen, Bhubaneswar',
        ),
        severity: IncidentSeverity.medium,
        status: IncidentStatus.open,
        crashConfidence: 0.76,
        notes: 'Moderate sudden deceleration detected. Awaiting dispatch triage.',
        metadata: {
          'peakGForce': 2.8,
          'peakAngularVelocity': 1.8,
          'trigger': 'Moderate deceleration spike',
        },
      ),
    ];

    for (final inc in defaultIncidents) {
      _incidents[inc.id] = inc;
    }
  }

  void addResponder(Responder responder) {
    _responders[responder.id] = responder;
  }

  void clearResponders() {
    _responders.clear();
  }

  void addIncident(Incident incident) {
    _incidents[incident.id] = incident;
  }

  void clearIncidents() {
    _incidents.clear();
  }

  @override
  Future<Incident> createIncident(Incident incident) async {
    _incidents[incident.id] = incident;
    return incident;
  }

  @override
  Future<Incident> updateIncident(Incident incident) async {
    _incidents[incident.id] = incident;
    return incident;
  }

  @override
  Future<Incident?> getIncident(String incidentId) async {
    return _incidents[incidentId];
  }

  @override
  Future<List<Incident>> getAllIncidents() async {
    final list = _incidents.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<List<Responder>> findNearestResponders(
    LocationData location, {
    double radiusKm = 10.0,
    ResponderType? type,
  }) async {
    final candidateList = <Responder>[];

    for (final responder in _responders.values) {
      if (type != null && responder.type != type) {
        continue;
      }
      final distance = calculateDistance(location, responder.location);
      if (distance <= radiusKm) {
        final eta = calculateETA(responder.location, location);
        candidateList.add(responder.copyWith(
          distanceKm: distance,
          etaMinutes: eta,
        ));
      }
    }

    // Sort ascending by distance
    candidateList.sort((a, b) => (a.distanceKm ?? 0.0).compareTo(b.distanceKm ?? 0.0));
    return candidateList;
  }

  @override
  Future<Incident> assignResponder(String incidentId, String responderId) async {
    final incident = _incidents[incidentId];
    if (incident == null) {
      throw Exception('Incident $incidentId not found');
    }
    final responder = _responders[responderId];
    if (responder == null) {
      throw Exception('Responder $responderId not found');
    }

    final updatedResponder = responder.copyWith(
      status: ResponderStatus.dispatched,
      assignedIncidentId: incidentId,
    );
    _responders[responderId] = updatedResponder;

    final updatedIncident = incident.copyWith(
      assignedResponderId: responderId,
      status: IncidentStatus.dispatched,
    );
    _incidents[incidentId] = updatedIncident;
    return updatedIncident;
  }

  @override
  Future<Responder> updateResponderStatus(
    String responderId,
    ResponderStatus status,
  ) async {
    final responder = _responders[responderId];
    if (responder == null) {
      throw Exception('Responder $responderId not found');
    }
    final updated = responder.copyWith(status: status);
    _responders[responderId] = updated;
    return updated;
  }

  @override
  Future<Responder> updateResponderLocation(
    String responderId,
    LocationData location,
  ) async {
    final responder = _responders[responderId];
    if (responder == null) {
      throw Exception('Responder $responderId not found');
    }
    final updated = responder.copyWith(location: location);
    _responders[responderId] = updated;
    return updated;
  }
}
