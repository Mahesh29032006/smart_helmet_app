/// Standardized WebSocket event model for bidirectional real-time communication.
class WebSocketEvent {
  /// Name of the event (e.g. 'incident.dispatched', 'responder.location_updated').
  final String event;

  /// Payload data associated with the event.
  final dynamic data;

  /// Timestamp when the event was emitted.
  final DateTime timestamp;

  /// Optional subscription or target incident ID.
  final String? incidentId;

  const WebSocketEvent({
    required this.event,
    this.data,
    required this.timestamp,
    this.incidentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'incidentId': incidentId,
    };
  }

  factory WebSocketEvent.fromMap(Map<String, dynamic> map) {
    return WebSocketEvent(
      event: map['event'] as String,
      data: map['data'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      incidentId: map['incidentId'] as String?,
    );
  }

  @override
  String toString() =>
      'WebSocketEvent(event: $event, incidentId: $incidentId, data: $data)';

  // Event Name Constants
  static const String incidentDispatched = 'incident.dispatched';
  static const String responderAccepted = 'responder.accepted';
  static const String responderRejected = 'responder.rejected';
  static const String responderLocationUpdated = 'responder.location_updated';
  static const String responderArrived = 'responder.arrived';
  static const String incidentClosed = 'incident.closed';
  static const String incidentCancelled = 'incident.cancelled';
  static const String incidentFailed = 'incident.failed';

  static const String clientAccept = 'responder.accept';
  static const String clientReject = 'responder.reject';
  static const String clientUpdateLocation = 'responder.update_location';
  static const String clientSubscribe = 'incident.subscribe';
  static const String clientUnsubscribe = 'incident.unsubscribe';
}
