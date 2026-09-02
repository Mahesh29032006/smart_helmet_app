import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/emergency_state.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/services/crash_detection_service.dart';
import 'package:emergency_response_app/core/services/state_machine_service.dart';

void main() {
  group('StateMachineService Tests', () {
    late StateMachineService service;
    late StreamController<CrashDetectionEvent> crashController;
    Incident? dispatchedIncident;

    setUp(() {
      dispatchedIncident = null;
      crashController = StreamController<CrashDetectionEvent>.broadcast();
      service = StateMachineService(
        initialCountdownSeconds: 2,
        getCurrentLocation: () => LocationData(
          latitude: 20.2961,
          longitude: 85.8245,
          timestamp: DateTime.now(),
        ),
        onDispatchTriggered: (inc) {
          dispatchedIncident = inc;
        },
      );
    });

    tearDown(() {
      service.dispose();
      crashController.close();
    });

    test('1. Initial state is idle and transitions to monitoring', () {
      expect(service.currentState, EmergencyState.idle);
      service.startMonitoring(crashController.stream);
      expect(service.currentState, EmergencyState.monitoring);
    });

    test('2. Crash detection event triggers countdown', () async {
      service.startMonitoring(crashController.stream);

      final stateHistory = <EmergencyState>[];
      final sub = service.stateStream.listen(stateHistory.add);

      crashController.add(CrashDetectionEvent(
        confidence: 0.98,
        peakGForce: 5.0,
        peakAngularVelocity: 3.5,
        timestamp: DateTime.now(),
        description: 'Test crash',
      ));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(service.currentState, EmergencyState.countdown);
      expect(stateHistory, contains(EmergencyState.countdown));

      await sub.cancel();
    });

    test('3. Countdown expiry automatically triggers emergency dispatch', () async {
      service.startMonitoring(crashController.stream);

      service.handleCrashDetected(CrashDetectionEvent(
        confidence: 0.98,
        peakGForce: 5.0,
        peakAngularVelocity: 3.5,
        timestamp: DateTime.now(),
        description: 'Test crash',
      ));

      expect(service.currentState, EmergencyState.countdown);

      // Wait for 2s countdown expiry
      await Future.delayed(const Duration(milliseconds: 2500));

      expect(service.currentState, EmergencyState.dispatched);
      expect(dispatchedIncident, isNotNull);
      expect(dispatchedIncident?.status, IncidentStatus.open);
    });

    test('4. User can cancel emergency during countdown', () async {
      service.startMonitoring(crashController.stream);
      service.startCountdown();

      expect(service.currentState, EmergencyState.countdown);
      service.cancelEmergency();

      expect(service.currentState, EmergencyState.cancelled);
      expect(dispatchedIncident, isNull);
    });

    test('5. User early confirmation triggers instant dispatch', () {
      service.startMonitoring(crashController.stream);
      service.startCountdown();

      service.confirmEmergency();
      expect(service.currentState, EmergencyState.dispatched);
      expect(dispatchedIncident, isNotNull);
    });

    test('6. Resolve and reset return to expected states', () {
      service.confirmEmergency();
      expect(service.currentState, EmergencyState.dispatched);

      service.resolveEmergency();
      expect(service.currentState, EmergencyState.resolved);

      service.reset();
      expect(service.currentState, EmergencyState.idle);
    });
  });
}
