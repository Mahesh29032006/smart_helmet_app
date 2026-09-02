import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/models/responder.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/services/mock_backend_api.dart';

void main() {
  group('MockBackendApiClient Tests', () {
    late MockBackendApiClient client;

    setUp(() {
      client = MockBackendApiClient();
    });

    test('1. Default seeded incidents and responders are available', () async {
      final incidents = await client.getAllIncidents();
      expect(incidents.length, greaterThanOrEqualTo(3));

      final responders = await client.findNearestResponders(
        LocationData(latitude: 20.2961, longitude: 85.8245, timestamp: DateTime.now()),
        radiusKm: 20.0,
      );
      expect(responders.isNotEmpty, isTrue);
    });

    test('2. Create, retrieve, and update incident', () async {
      final newInc = Incident(
        id: 'inc-test-999',
        timestamp: DateTime.now(),
        location: LocationData(
          latitude: 20.3000,
          longitude: 85.8300,
          timestamp: DateTime.now(),
          address: 'Test Location',
        ),
        severity: IncidentSeverity.high,
        status: IncidentStatus.open,
      );

      await client.createIncident(newInc);

      final retrieved = await client.getIncident('inc-test-999');
      expect(retrieved, isNotNull);
      expect(retrieved?.location.address, 'Test Location');

      final updated = retrieved!.copyWith(status: IncidentStatus.inProgress);
      await client.updateIncident(updated);

      final reRetrieved = await client.getIncident('inc-test-999');
      expect(reRetrieved?.status, IncidentStatus.inProgress);
    });

    test('3. Nearest responders query filters by radius and type', () async {
      final loc = LocationData(
        latitude: 20.2961,
        longitude: 85.8245,
        timestamp: DateTime.now(),
      );

      // Query within tight 1.0 km radius
      final closeResponders = await client.findNearestResponders(
        loc,
        radiusKm: 1.0,
        type: ResponderType.ambulance,
      );
      expect(closeResponders.length, 1);
      expect(closeResponders.first.id, 'amb-01');

      // Query hospital type
      final hospitals = await client.findNearestResponders(
        loc,
        radiusKm: 10.0,
        type: ResponderType.hospital,
      );
      expect(hospitals.isNotEmpty, isTrue);
      expect(hospitals.every((h) => h.type == ResponderType.hospital), isTrue);
    });

    test('4. Update responder status and location', () async {
      await client.updateResponderStatus('amb-01', ResponderStatus.enRoute);

      final loc = LocationData(
        latitude: 20.2980,
        longitude: 85.8260,
        timestamp: DateTime.now(),
      );
      final updated = await client.updateResponderLocation('amb-01', loc);
      expect(updated.status, ResponderStatus.enRoute);
      expect(updated.location.latitude, 20.2980);
    });
  });
}
