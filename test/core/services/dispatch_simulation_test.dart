import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/dispatch_simulation_config.dart';
import 'package:emergency_response_app/core/models/dispatch_status.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/models/responder.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/services/dispatch_simulation.dart';

void main() {
  group('DispatchSimulation Tests', () {
    late Incident testIncident;
    late Responder testAmbulance;
    late Responder testHospital;

    setUp(() {
      testIncident = Incident(
        id: 'inc-sim-01',
        timestamp: DateTime.now(),
        location: LocationData(
          latitude: 20.2961,
          longitude: 85.8245,
          timestamp: DateTime.now(),
        ),
      );

      testAmbulance = Responder(
        id: 'amb-sim-01',
        name: 'Sim Ambulance',
        type: ResponderType.ambulance,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3015,
          longitude: 85.8290,
          timestamp: DateTime.now(),
        ),
        phone: '108',
      );

      testHospital = Responder(
        id: 'hosp-sim-01',
        name: 'Sim Hospital',
        type: ResponderType.hospital,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3120,
          longitude: 85.8390,
          timestamp: DateTime.now(),
        ),
        phone: '100',
        traumaCapability: true,
      );
    });

    test('Runs automated lifecycle with fast durations', () async {
      final statuses = <DispatchStatus>[];
      final locationUpdates = <Responder>[];
      final logs = <String>[];

      // Use very short durations for fast unit test
      final fastConfig = DispatchSimulationConfig(
        searchDuration: const Duration(milliseconds: 20),
        acceptDuration: const Duration(milliseconds: 20),
        enRouteDuration: const Duration(milliseconds: 40),
        arriveDuration: const Duration(milliseconds: 20),
        transportDuration: const Duration(milliseconds: 40),
        deliverDuration: const Duration(milliseconds: 20),
        completeDuration: const Duration(milliseconds: 20),
        movementUpdateInterval: const Duration(milliseconds: 10),
        autoAccept: true,
        autoMove: true,
      );

      final simulation = DispatchSimulation(
        config: fastConfig,
        onStatusChanged: statuses.add,
        onLocationUpdated: locationUpdates.add,
        onLog: logs.add,
      );

      expect(simulation.isRunning, isFalse);

      await simulation.runSimulation(
        incident: testIncident,
        responder: testAmbulance,
        hospital: testHospital,
      );

      expect(simulation.isRunning, isFalse);
      expect(
        statuses,
        containsAllInOrder([
          DispatchStatus.searching,
          DispatchStatus.dispatched,
          DispatchStatus.acknowledged,
          DispatchStatus.enRoute,
          DispatchStatus.arrived,
          DispatchStatus.transporting,
          DispatchStatus.delivered,
          DispatchStatus.completed,
        ]),
      );

      expect(locationUpdates.isNotEmpty, isTrue);
      expect(logs.isNotEmpty, isTrue);
    });

    test('Can be cancelled mid-flight', () async {
      final statuses = <DispatchStatus>[];

      final longConfig = DispatchSimulationConfig(
        searchDuration: const Duration(seconds: 10),
        acceptDuration: const Duration(seconds: 10),
      );

      final simulation = DispatchSimulation(
        config: longConfig,
        onStatusChanged: statuses.add,
        onLocationUpdated: (_) {},
      );

      // Start in background without awaiting completion
      simulation.runSimulation(
        incident: testIncident,
        responder: testAmbulance,
        hospital: testHospital,
      );

      expect(simulation.isRunning, isTrue);
      simulation.cancel();
      expect(simulation.isRunning, isFalse);
    });
  });
}
