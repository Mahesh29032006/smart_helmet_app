import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/admin/screens/admin_dashboard_screen.dart';

void main() {
  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('Admin dashboard shows executive metrics cards and active incident list', (tester) async {
      final sampleIncidents = [
        Incident(
          id: 'inc-001',
          timestamp: DateTime.now(),
          location: LocationData(
            latitude: 20.2961,
            longitude: 85.8245,
            timestamp: DateTime.now(),
            address: 'Station Square, Bhubaneswar',
          ),
          severity: IncidentSeverity.critical,
          status: IncidentStatus.open,
        ),
        Incident(
          id: 'inc-002',
          timestamp: DateTime.now(),
          location: LocationData(
            latitude: 20.3200,
            longitude: 85.8100,
            timestamp: DateTime.now(),
          ),
          severity: IncidentSeverity.medium,
          status: IncidentStatus.resolved,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incidentsListProvider.overrideWith((ref) => Future.value(sampleIncidents)),
            activeIncidentsProvider.overrideWith((ref) => Future.value([sampleIncidents.first])),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Admin Command Center'), findsOneWidget);
      expect(find.text('ACTIVE INCIDENTS'), findsOneWidget);
      expect(find.text('AVG RESPONSE TIME'), findsOneWidget);
      expect(find.text('TOTAL TODAY'), findsOneWidget);
      expect(find.text('RESOLUTION RATE'), findsOneWidget);
      expect(find.text('Active Response Fleet'), findsOneWidget);
      expect(find.text('Active Emergency Incidents'), findsOneWidget);
      expect(find.text('inc-001'), findsOneWidget);
    });
  });
}
