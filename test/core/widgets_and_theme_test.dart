import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emergency_response_app/core/models/dispatch_status.dart';
import 'package:emergency_response_app/core/models/emergency_state.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/services/ui_logger.dart';
import 'package:emergency_response_app/core/theme/app_theme.dart';
import 'package:emergency_response_app/core/widgets/app_drawer.dart';
import 'package:emergency_response_app/core/widgets/loading_indicator.dart';
import 'package:emergency_response_app/core/widgets/severity_indicator.dart';
import 'package:emergency_response_app/core/widgets/status_badge.dart';
import 'package:emergency_response_app/main.dart';

void main() {
  group('Core Widgets & Theme Tests', () {
    test('AppTheme creates valid light and dark ThemeData', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(AppTheme.primaryColor, const Color(0xFF1A73E8));
      expect(AppTheme.dangerColor, const Color(0xFFD32F2F));
    });

    test('UiLogger records and clears interaction logs', () {
      UiLogger.clear();
      expect(UiLogger.logs.isEmpty, isTrue);

      UiLogger.log('Test action executed');
      expect(UiLogger.logs.length, 1);
      expect(UiLogger.logs.first, contains('Test action executed'));

      UiLogger.clear();
      expect(UiLogger.logs.isEmpty, isTrue);
    });

    testWidgets('StatusBadge renders for different enums', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge.fromIncidentStatus(IncidentStatus.open),
                StatusBadge.fromEmergencyState(EmergencyState.countdown),
                StatusBadge.fromDispatchStatus(DispatchStatus.enRoute),
                StatusBadge.fromResponderStatus(ResponderStatus.available),
              ],
            ),
          ),
        ),
      );

      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('COUNTDOWN ACTIVE'), findsOneWidget);
      expect(find.text('EN ROUTE'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
    });

    testWidgets('SeverityIndicator renders critical and compact versions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SeverityIndicator(severity: IncidentSeverity.critical),
                SeverityIndicator(severity: IncidentSeverity.low, compact: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('CRITICAL SEVERITY'), findsOneWidget);
      expect(find.text('LOW'), findsOneWidget);
    });

    testWidgets('LoadingIndicator renders with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Testing loader'),
          ),
        ),
      );

      expect(find.text('Testing loader'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppDrawer renders all navigation entries', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: AppDrawer(currentRoute: '/'),
            ),
          ),
        ),
      );

      // Open drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('RescueLink'), findsOneWidget);
      expect(find.text('Home / Live Monitor'), findsOneWidget);
      expect(find.text('Incident List'), findsOneWidget);
      expect(find.text('Real-Time Map'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Hospital Dashboard'), findsOneWidget);
      expect(find.text('Ambulance Dashboard'), findsOneWidget);

      final drawerScrollable = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        find.text('System Diagnostics'),
        150,
        scrollable: drawerScrollable,
      );
      expect(find.text('System Diagnostics'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Settings & Config'),
        150,
        scrollable: drawerScrollable,
      );
      expect(find.text('Settings & Config'), findsOneWidget);
    });

    testWidgets('EmergencyResponseApp full widget tree boots up with GoRouter', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EmergencyResponseApp(),
        ),
      );

      await tester.pump();
      expect(find.text('Live Monitor & Crash Telemetry'), findsOneWidget);
    });
  });
}
