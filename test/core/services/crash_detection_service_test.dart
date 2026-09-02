import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/sensor_data.dart';
import 'package:emergency_response_app/core/services/crash_detection_service.dart';

void main() {
  group('CrashDetectionService Tests', () {
    late CrashDetectionService service;
    late StreamController<SensorData> sensorController;

    setUp(() {
      service = CrashDetectionService(
        gForceThreshold: 3.0,
        angularVelocityThreshold: 2.5,
      );
      sensorController = StreamController<SensorData>.broadcast();
      service.startListening(sensorController.stream);
    });

    tearDown(() {
      service.dispose();
      sensorController.close();
    });

    test('1. Normal driving telemetry does not trigger crash event', () async {
      final events = <CrashDetectionEvent>[];
      final sub = service.crashStream.listen(events.add);

      // Normal driving values: 1G vertical gravity (9.8 m/s^2) -> gForce = 1.0 (< 3.0 G)
      sensorController.add(SensorData(
        accelerometerX: 0.1,
        accelerometerY: 0.2,
        accelerometerZ: 9.8,
        gyroscopeX: 0.05,
        gyroscopeY: 0.02,
        gyroscopeZ: 0.01,
        timestamp: DateTime.now(),
        speedKmph: 45.0,
      ));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(events.isEmpty, isTrue);

      await sub.cancel();
    });

    test('2. High G-Force alone triggers crash event with high confidence', () async {
      final events = <CrashDetectionEvent>[];
      final sub = service.crashStream.listen(events.add);

      // High G-Force spike (5.0 G * 9.8 = 49.0 m/s^2 > 3.0 G * 1.5)
      sensorController.add(SensorData(
        accelerometerX: 49.0,
        accelerometerY: 0.0,
        accelerometerZ: 0.0,
        gyroscopeX: 0.1,
        gyroscopeY: 0.1,
        gyroscopeZ: 0.1,
        timestamp: DateTime.now(),
        speedKmph: 60.0,
      ));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(events.isNotEmpty, isTrue);
      expect(events.first.peakGForce, closeTo(5.0, 0.1));
      expect(events.first.confidence, greaterThanOrEqualTo(0.90));

      await sub.cancel();
    });

    test('3. High Angular Velocity alone triggers rollover crash event', () async {
      final events = <CrashDetectionEvent>[];
      final sub = service.crashStream.listen(events.add);

      // High angular velocity (> 2.5 * 1.5 = 3.75 rad/s)
      sensorController.add(SensorData(
        accelerometerX: 0.0,
        accelerometerY: 0.0,
        accelerometerZ: 9.8,
        gyroscopeX: 3.0,
        gyroscopeY: 3.0,
        gyroscopeZ: 0.0,
        timestamp: DateTime.now(),
        speedKmph: 50.0,
      ));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(events.isNotEmpty, isTrue);
      expect(events.first.peakAngularVelocity, closeTo(4.24, 0.05));
      expect(events.first.confidence, greaterThanOrEqualTo(0.85));

      await sub.cancel();
    });

    test('4. Combined G-Force + Rollover yields critical 0.98 confidence score', () async {
      final events = <CrashDetectionEvent>[];
      final sub = service.crashStream.listen(events.add);

      // Dual trigger: 4.5G and 3.2 rad/s
      sensorController.add(SensorData(
        accelerometerX: 44.1,
        accelerometerY: 0.0,
        accelerometerZ: 0.0,
        gyroscopeX: 3.2,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
        timestamp: DateTime.now(),
        speedKmph: 80.0,
      ));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(events.isNotEmpty, isTrue);
      expect(events.first.confidence, 0.98);
      expect(events.first.description, contains('Multi-signal'));

      await sub.cancel();
    });
  });
}
