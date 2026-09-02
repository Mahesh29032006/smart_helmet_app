import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/hardware_telemetry.dart';

void main() {
  group('Hardware Telemetry Models Tests', () {
    test('SensorDataHardware.fromHardwareSensorEvent parses complete data correctly', () {
      final data = {
        'accelerometerX': 1.1,
        'accelerometerY': -0.5,
        'accelerometerZ': 9.8,
        'gyroscopeX': 0.1,
        'gyroscopeY': 0.2,
        'gyroscopeZ': -0.1,
        'speedKmph': 15.0,
      };

      final sensor = SensorDataHardware.fromHardwareSensorEvent(data);

      expect(sensor.accelerometerX, 1.1);
      expect(sensor.accelerometerY, -0.5);
      expect(sensor.accelerometerZ, 9.8);
      expect(sensor.gyroscopeX, 0.1);
      expect(sensor.gyroscopeY, 0.2);
      expect(sensor.gyroscopeZ, -0.1);
    });

    test('LocationDataHardware.fromHardwareLocationEvent returns valid location when fix is true', () {
      final data = {
        'fix': true,
        'latitude': 22.2527,
        'longitude': 84.9138,
        'altitude': 217.9,
        'speedKmph': 5.0,
      };

      final location = LocationDataHardware.fromHardwareLocationEvent(data);

      expect(location, isNotNull);
      expect(location!.latitude, 22.2527);
      expect(location.longitude, 84.9138);
      expect(location.altitude, 217.9);
      expect(location.speed, 5.0 / 3.6); // km/h to m/s
    });

    test('LocationDataHardware.fromHardwareLocationEvent returns null when fix is false', () {
      final data = {
        'fix': false,
        'latitude': 22.2527,
        'longitude': 84.9138,
      };

      final location = LocationDataHardware.fromHardwareLocationEvent(data);
      expect(location, isNull);
    });
  });
}
