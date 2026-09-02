import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/features/settings/screens/settings_screen.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('Settings screen displays calibration sliders and demo mode toggles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('System Settings & Calibration'), findsOneWidget);
      expect(find.text('APPEARANCE & THEME'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('PRESENTATION & DEMO MODE'), findsOneWidget);
      expect(find.text('Demo Mode (Auto-Crash)'), findsOneWidget);
      expect(find.text('Show Debug Sensor Telemetry'), findsOneWidget);
      expect(find.text('Auditory Emergency Chimes'), findsOneWidget);
      expect(find.text('Haptic Vibration Alerts'), findsOneWidget);
      expect(find.text('CRASH DETECTION ALGORITHM CALIBRATION'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Backend API URL'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Backend API URL'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('UI INTERACTION & AUDIT LOGS'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('UI INTERACTION & AUDIT LOGS'), findsOneWidget);
    });
  });
}
