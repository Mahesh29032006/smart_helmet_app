import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/responder_status.dart';

/// Abstract contract for Backend API interactions.
abstract class BackendApiClient {
  Future<Incident> createIncident(Incident incident);
  Future<Incident> updateIncident(Incident incident);
  Future<Incident?> getIncident(String incidentId);
  Future<List<Responder>> findNearestResponders(
    LocationData location, {
    double radiusKm = 10.0,
    ResponderType? type,
  });
  Future<Incident> assignResponder(String incidentId, String responderId);
  Future<Responder> updateResponderStatus(String responderId, ResponderStatus status);
  Future<Responder> updateResponderLocation(String responderId, LocationData location);
}
