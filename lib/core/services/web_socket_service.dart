import 'dart:async';
import '../models/web_socket_event.dart';

/// Real-time bidirectional WebSocket & Socket.IO communication service.
class WebSocketService {
  final String? defaultUrl;
  bool _isConnected = false;
  String? _currentUrl;
  final Set<String> _subscribedIncidents = {};

  final _eventController = StreamController<WebSocketEvent>.broadcast(sync: true);
  final _connectionController = StreamController<bool>.broadcast(sync: true);

  // For testing / simulated server loopback
  void Function(String event, dynamic data)? onSendListener;

  WebSocketService([this.defaultUrl]);

  /// Whether the WebSocket connection is currently active.
  bool get isConnected => _isConnected;

  /// Current connected endpoint URL.
  String? get currentUrl => _currentUrl;

  /// Set of currently subscribed incident IDs.
  Set<String> get subscribedIncidents => Set.unmodifiable(_subscribedIncidents);

  /// Stream of all incoming WebSocket events.
  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  /// Stream of connection state changes (true = connected, false = disconnected).
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  /// Establishes connection to the WebSocket server endpoint.
  Future<void> connect([String? url]) async {
    final targetUrl = url ?? defaultUrl ?? 'ws://localhost:5000/socket.io';
    _currentUrl = targetUrl;
    _isConnected = true;
    _connectionController.add(true);
  }

  /// Closes the active WebSocket connection.
  Future<void> disconnect() async {
    if (!_isConnected) return;
    _isConnected = false;
    _connectionController.add(false);
    _subscribedIncidents.clear();
  }

  /// Dispatches an event with payload to the server.
  void send(String event, dynamic data, {String? incidentId}) {
    if (onSendListener != null) {
      onSendListener!(event, data);
    }
  }

  /// Subscribes to real-time events for a specific incident room.
  void subscribeToIncident(String incidentId) {
    _subscribedIncidents.add(incidentId);
    send(WebSocketEvent.clientSubscribe, {'incidentId': incidentId},
        incidentId: incidentId);
  }

  /// Unsubscribes from real-time events for a specific incident room.
  void unsubscribeFromIncident(String incidentId) {
    _subscribedIncidents.remove(incidentId);
    send(WebSocketEvent.clientUnsubscribe, {'incidentId': incidentId},
        incidentId: incidentId);
  }

  /// Simulates receiving an incoming event from the remote backend.
  void receiveEvent(WebSocketEvent event) {
    // If event is tied to a specific incident and subscriptions exist, only deliver if subscribed
    if (event.incidentId != null &&
        _subscribedIncidents.isNotEmpty &&
        !_subscribedIncidents.contains(event.incidentId)) {
      return;
    }
    _eventController.add(event);
  }

  /// Helper to emit an event by name and payload.
  void emitServerEvent(String eventName, dynamic data, {String? incidentId}) {
    receiveEvent(WebSocketEvent(
      event: eventName,
      data: data,
      timestamp: DateTime.now(),
      incidentId: incidentId,
    ));
  }

  /// Cleanup resources.
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
