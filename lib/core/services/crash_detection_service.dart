import 'dart:async';
import '../models/sensor_data.dart';

/// Crash event payload emitted when anomaly conditions are met.
class CrashDetectionEvent {
  final double confidence;
  final double peakGForce;
  final double peakAngularVelocity;
  final DateTime timestamp;
  final String description;

  const CrashDetectionEvent({
    required this.confidence,
    required this.peakGForce,
    required this.peakAngularVelocity,
    required this.timestamp,
    required this.description,
  });
}

/// Multi-signal real-time vehicle crash detection service.
class CrashDetectionService {
  final double gForceThreshold;
  final double angularVelocityThreshold;
  final _crashController = StreamController<CrashDetectionEvent>.broadcast();
  StreamSubscription<SensorData>? _subscription;

  CrashDetectionService({
    this.gForceThreshold = 3.0,
    this.angularVelocityThreshold = 2.5,
  });

  Stream<CrashDetectionEvent> get crashStream => _crashController.stream;

  void startListening(Stream<SensorData> sensorStream) {
    _subscription?.cancel();
    _subscription = sensorStream.listen((data) {
      _processSensorData(data);
    });
  }

  void _processSensorData(SensorData data) {
    final gForce = data.gForce;
    final angularVel = data.totalAngularVelocity;

    if (gForce >= gForceThreshold || angularVel >= angularVelocityThreshold) {
      double confidence = 0.5;
      if (gForce >= gForceThreshold && angularVel >= angularVelocityThreshold) {
        confidence = 0.98;
      } else if (gForce >= gForceThreshold * 1.5) {
        confidence = 0.92;
      } else if (angularVel >= angularVelocityThreshold * 1.5) {
        confidence = 0.85;
      }

      final event = CrashDetectionEvent(
        confidence: confidence,
        peakGForce: gForce,
        peakAngularVelocity: angularVel,
        timestamp: data.timestamp,
        description: 'Multi-signal crash trigger (G: ${gForce.toStringAsFixed(2)}, Rot: ${angularVel.toStringAsFixed(2)} rad/s)',
      );
      _crashController.add(event);
    }
  }

  void stop() {
    _subscription?.cancel();
  }

  void dispose() {
    stop();
    _crashController.close();
  }
}
