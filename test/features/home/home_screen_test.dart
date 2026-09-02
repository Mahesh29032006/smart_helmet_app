import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/emergency_state.dart';
import 'package:emergency_response_app/core/models/sensor_data.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/home/screens/home_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('Home screen displays live sensor values and system status', (tester) async {
      final testSensorData = SensorData(
        accelerometerX: 1.2,
        accelerometerY: 9.8,
        accelerometerZ: 0.5,
        gyroscopeX: 0.2,
        gyroscopeY: 0.1,
        gyroscopeZ: 0.3,
        speedKmph: 65.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSensorDataProvider.overrideWithValue(testSensorData),
            emergencyStateProvider.overrideWith((ref) => Stream.value(EmergencyState.monitoring)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify header and sections
      expect(find.text('Live Monitor & Crash Telemetry'), findsOneWidget);
      expect(find.text('SYSTEM STATE'), findsOneWidget);
      expect(find.text('MONITORING'), findsWidgets);
      expect(find.text('Live IMU Telemetry'), findsOneWidget);
      expect(find.text('65 km/h'), findsOneWidget);
      expect(find.text('GPS Live Position'), findsOneWidget);
    });

    testWidgets('Countdown overlay appears on HomeScreen when state is countdown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emergencyStateProvider.overrideWith((ref) => Stream.value(EmergencyState.countdown)),
            countdownProvider.overrideWith((ref) => Stream.value(9)),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify countdown overlay appears
      expect(find.text('9'), findsOneWidget);
      expect(find.text("I'M OK - CANCEL SOS"), findsOneWidget);
    });
  });
}
