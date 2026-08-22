import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/responder_status.dart';
import 'backend_api.dart';

/// In-memory mock backend API with sample emergency assets and Haversine sorting.
class MockBackendApiClient implements BackendApiClient {
  final Map<String, Incident> _incidents = {};
  final Map<String, Responder> _responders = {};

  MockBackendApiClient({List<Responder>? initialResponders}) {
    if (initialResponders != null) {
      for (final r in initialResponders) {
        _responders[r.id] = r;
      }
    } else {
      _seedDefaultResponders();
    }
  }

  void _seedDefaultResponders() {
    // Reference center (e.g. Bhubaneswar 20.2961, 85.8245)
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

  void addResponder(Responder responder) {
    _responders[responder.id] = responder;
  }

  void clearResponders() {
    _responders.clear();
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
