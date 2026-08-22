import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/dispatch_config.dart';
import 'package:emergency_response_app/core/models/dispatch_status.dart';
import 'package:emergency_response_app/core/models/emergency_state.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/models/responder.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/models/web_socket_event.dart';
import 'package:emergency_response_app/core/services/dispatch_service.dart';
import 'package:emergency_response_app/core/services/mock_backend_api.dart';
import 'package:emergency_response_app/core/services/state_machine_service.dart';
import 'package:emergency_response_app/core/services/web_socket_service.dart';

void main() {
  group('DispatchService Tests', () {
    late MockBackendApiClient backendClient;
    late WebSocketService webSocketService;
    late DispatchService dispatchService;
    late Incident testIncident;

    setUp(() {
      backendClient = MockBackendApiClient();
      webSocketService = WebSocketService();
      dispatchService = DispatchService(
        config: const DispatchConfig(
          useSimulation: false, // Manual control for deterministic testing
          autoProgressSimulation: false,
        ),
        backendClient: backendClient,
        webSocketService: webSocketService,
      );

      testIncident = Incident(
        id: 'inc-test-001',
        timestamp: DateTime.now(),
        location: LocationData(
          latitude: 20.2961,
          longitude: 85.8245,
          timestamp: DateTime.now(),
          address: 'Test Incident Location',
        ),
        severity: IncidentSeverity.critical,
        status: IncidentStatus.open,
      );
    });

    tearDown(() {
      dispatchService.dispose();
      webSocketService.dispose();
    });

    test('1. Start dispatch transitions through searching to dispatched with assigned responder', () async {
      final statuses = <DispatchStatus>[];
      final sub = dispatchService.dispatchStatusStream.listen(statuses.add);

      await dispatchService.startDispatch(testIncident);

      expect(dispatchService.currentStatus, DispatchStatus.dispatched);
      expect(statuses, containsAllInOrder([DispatchStatus.searching, DispatchStatus.dispatched]));
      expect(dispatchService.assignedResponder, isNotNull);
      expect(dispatchService.assignedResponder!.id, 'amb-01');
      expect(dispatchService.assignedHospital, isNotNull);
      expect(dispatchService.assignedHospital!.traumaCapability, isTrue);
      expect(dispatchService.currentIncident?.status, IncidentStatus.dispatched);

      await sub.cancel();
    });

    test('2. Responder accepts dispatch -> status transitions to acknowledged', () async {
      await dispatchService.startDispatch(testIncident);
      expect(dispatchService.currentStatus, DispatchStatus.dispatched);

      await dispatchService.acceptDispatch('amb-01');
      expect(dispatchService.currentStatus, DispatchStatus.acknowledged);
    });

    test('3. Responder rejects dispatch -> re-assigns next nearest responder', () async {
      await dispatchService.startDispatch(testIncident);
      expect(dispatchService.assignedResponder!.id, 'amb-01');

      await dispatchService.rejectDispatch('amb-01');

      // Next closest ambulance is amb-02
      expect(dispatchService.assignedResponder, isNotNull);
      expect(dispatchService.assignedResponder!.id, 'amb-02');
      expect(dispatchService.currentStatus, DispatchStatus.dispatched);
    });

    test('4. Update responder status to enRoute -> status transitions to enRoute', () async {
      await dispatchService.startDispatch(testIncident);
      await dispatchService.acceptDispatch('amb-01');
      await dispatchService.updateResponderStatus('amb-01', ResponderStatus.enRoute);

      expect(dispatchService.currentStatus, DispatchStatus.enRoute);
    });

    test('5. Update responder status to arrived -> status transitions to arrived', () async {
      await dispatchService.startDispatch(testIncident);
      await dispatchService.updateResponderStatus('amb-01', ResponderStatus.arrived);

      expect(dispatchService.currentStatus, DispatchStatus.arrived);
    });

    test('6. Update responder status to transporting -> status transitions to transporting', () async {
      await dispatchService.startDispatch(testIncident);
      await dispatchService.updateResponderStatus('amb-01', ResponderStatus.transporting);

      expect(dispatchService.currentStatus, DispatchStatus.transporting);
    });

    test('7. Update responder status to available after transporting -> status transitions to delivered', () async {
      await dispatchService.startDispatch(testIncident);
      await dispatchService.updateResponderStatus('amb-01', ResponderStatus.transporting);
      await dispatchService.updateResponderStatus('amb-01', ResponderStatus.available);

      expect(dispatchService.currentStatus, DispatchStatus.delivered);
    });

    test('8. Complete dispatch -> status transitions to completed and incident is resolved', () async {
      await dispatchService.startDispatch(testIncident);
      await dispatchService.completeDispatch(testIncident.id);

      expect(dispatchService.currentStatus, DispatchStatus.completed);
      expect(dispatchService.currentIncident?.status, IncidentStatus.resolved);
    });

    test('9. Cancel dispatch -> status transitions to cancelled and incident is cancelled', () async {
      await dispatchService.startDispatch(testIncident);
      await dispatchService.cancelDispatch(testIncident.id);

      expect(dispatchService.currentStatus, DispatchStatus.cancelled);
      expect(dispatchService.currentIncident?.status, IncidentStatus.cancelled);
    });

    test('10. No responders available within radius -> status transitions to failed', () async {
      backendClient.clearResponders(); // Empty all available units

      await dispatchService.startDispatch(testIncident);

      expect(dispatchService.currentStatus, DispatchStatus.failed);
      expect(dispatchService.assignedResponder, isNull);
    });

    test('11. Update responder location calculates distance and ETA', () async {
      await dispatchService.startDispatch(testIncident);

      final newLoc = LocationData(
        latitude: 20.2970,
        longitude: 85.8250,
        timestamp: DateTime.now(),
      );

      final responderUpdates = <Responder>[];
      final sub = dispatchService.responderLocationStream.listen(responderUpdates.add);

      await dispatchService.updateResponderLocation('amb-01', newLoc);

      expect(responderUpdates.isNotEmpty, isTrue);
      expect(dispatchService.assignedResponder?.location.latitude, 20.2970);
      expect(dispatchService.assignedResponder?.distanceKm, isNotNull);
      expect(dispatchService.assignedResponder?.etaMinutes, isNotNull);

      await sub.cancel();
    });

    test('12. Incoming WebSocket events update DispatchService status reactively', () async {
      await webSocketService.connect();
      await dispatchService.startDispatch(testIncident);

      webSocketService.emitServerEvent(
        WebSocketEvent.responderAccepted,
        {'responderId': 'amb-01'},
        incidentId: testIncident.id,
      );
      expect(dispatchService.currentStatus, DispatchStatus.acknowledged);

      webSocketService.emitServerEvent(
        WebSocketEvent.responderArrived,
        {'responderId': 'amb-01'},
        incidentId: testIncident.id,
      );
      expect(dispatchService.currentStatus, DispatchStatus.arrived);

      webSocketService.emitServerEvent(
        WebSocketEvent.incidentClosed,
        {'incidentId': testIncident.id},
        incidentId: testIncident.id,
      );
      expect(dispatchService.currentStatus, DispatchStatus.completed);
    });

    test('13. StateMachineService transition to dispatched triggers DispatchService', () async {
      final stateMachine = StateMachineService(
        initialCountdownSeconds: 1,
        onDispatchTriggered: (incident) {
          dispatchService.startDispatch(incident);
        },
      );

      stateMachine.confirmEmergency();

      // Wait a microtask for startDispatch async search to complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(stateMachine.currentState, EmergencyState.dispatched);
      expect(dispatchService.currentStatus, DispatchStatus.dispatched);
      expect(dispatchService.assignedResponder, isNotNull);

      stateMachine.dispose();
    });
  });
}
