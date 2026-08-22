import 'dart:async';
import 'dart:math' as math;
import '../models/sensor_data.dart';

/// Simulates normal and abnormal vehicle motion telemetry profiles.
class SensorSimulator {
  final _sensorController = StreamController<SensorData>.broadcast();
  Timer? _timer;
  bool _isRunning = false;

  Stream<SensorData> get sensorStream => _sensorController.stream;
  bool get isRunning => _isRunning;

  void startNormalDriving({Duration interval = const Duration(milliseconds: 100)}) {
    _timer?.cancel();
    _isRunning = true;
    final random = math.Random();

    _timer = Timer.periodic(interval, (_) {
      final now = DateTime.now();
      final data = SensorData(
        accelerometerX: (random.nextDouble() - 0.5) * 0.4,
        accelerometerY: 9.8 + (random.nextDouble() - 0.5) * 0.3,
        accelerometerZ: (random.nextDouble() - 0.5) * 0.4,
        gyroscopeX: (random.nextDouble() - 0.5) * 0.1,
        gyroscopeY: (random.nextDouble() - 0.5) * 0.1,
        gyroscopeZ: (random.nextDouble() - 0.5) * 0.1,
        speedKmph: 50.0 + (random.nextDouble() - 0.5) * 5.0,
        timestamp: now,
      );
      _sensorController.add(data);
    });
  }

  void injectCrashEvent({double gForce = 4.5, double rollRadS = 3.5}) {
    final now = DateTime.now();
    final data = SensorData(
      accelerometerX: gForce * 9.80665 * 0.7,
      accelerometerY: gForce * 9.80665 * 0.7,
      accelerometerZ: 9.80665,
      gyroscopeX: rollRadS,
      gyroscopeY: rollRadS * 0.5,
      gyroscopeZ: 0.2,
      speedKmph: 0.0,
      timestamp: now,
    );
    _sensorController.add(data);
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  void dispose() {
    stop();
    _sensorController.close();
  }
}
