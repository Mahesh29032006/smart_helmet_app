import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/web_socket_event.dart';
import 'package:emergency_response_app/core/services/web_socket_service.dart';

void main() {
  group('WebSocketService Tests', () {
    late WebSocketService wsService;

    setUp(() {
      wsService = WebSocketService('ws://localhost:5000/socket.io');
    });

    tearDown(() {
      wsService.dispose();
    });

    test('1. Connect establishes connection and updates stream', () async {
      expect(wsService.isConnected, isFalse);

      final connectionStates = <bool>[];
      final sub = wsService.connectionStatusStream.listen(connectionStates.add);

      await wsService.connect();

      expect(wsService.isConnected, isTrue);
      expect(wsService.currentUrl, 'ws://localhost:5000/socket.io');
      expect(connectionStates, contains(true));

      await sub.cancel();
    });

    test('2. Disconnect closes active connection', () async {
      await wsService.connect();
      expect(wsService.isConnected, isTrue);

      await wsService.disconnect();
      expect(wsService.isConnected, isFalse);
      expect(wsService.subscribedIncidents.isEmpty, isTrue);
    });

    test('3. Subscribe and unsubscribe manage incident rooms', () async {
      String? sentEvent;
      dynamic sentData;

      wsService.onSendListener = (event, data) {
        sentEvent = event;
        sentData = data;
      };

      wsService.subscribeToIncident('inc-100');
      expect(wsService.subscribedIncidents.contains('inc-100'), isTrue);
      expect(sentEvent, WebSocketEvent.clientSubscribe);
      expect(sentData['incidentId'], 'inc-100');

      wsService.unsubscribeFromIncident('inc-100');
      expect(wsService.subscribedIncidents.contains('inc-100'), isFalse);
      expect(sentEvent, WebSocketEvent.clientUnsubscribe);
    });

    test('4. Send dispatches payload to listener', () {
      String? sentEvent;
      dynamic sentData;

      wsService.onSendListener = (event, data) {
        sentEvent = event;
        sentData = data;
      };

      wsService.send(WebSocketEvent.clientAccept, {'responderId': 'amb-01'});
      expect(sentEvent, WebSocketEvent.clientAccept);
      expect(sentData['responderId'], 'amb-01');
    });

    test('5. Receive event emits to eventStream for matching subscription', () async {
      wsService.subscribeToIncident('inc-200');

      final receivedEvents = <WebSocketEvent>[];
      final sub = wsService.eventStream.listen(receivedEvents.add);

      final matchingEvent = WebSocketEvent(
        event: WebSocketEvent.responderAccepted,
        data: {'responderId': 'amb-01'},
        timestamp: DateTime.now(),
        incidentId: 'inc-200',
      );

      final nonMatchingEvent = WebSocketEvent(
        event: WebSocketEvent.responderAccepted,
        data: {'responderId': 'amb-02'},
        timestamp: DateTime.now(),
        incidentId: 'inc-999', // Different incident
      );

      wsService.receiveEvent(matchingEvent);
      wsService.receiveEvent(nonMatchingEvent);

      expect(receivedEvents.length, 1);
      expect(receivedEvents.first.incidentId, 'inc-200');

      await sub.cancel();
    });
  });
}
