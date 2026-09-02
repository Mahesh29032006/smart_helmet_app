import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/incidents/screens/incident_list_screen.dart';

void main() {
  group('IncidentListScreen Widget Tests', () {
    testWidgets('Incident list screen shows all incidents and filter chips', (tester) async {
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
          crashConfidence: 0.98,
        ),
        Incident(
          id: 'inc-002',
          timestamp: DateTime.now(),
          location: LocationData(
            latitude: 20.3200,
            longitude: 85.8100,
            timestamp: DateTime.now(),
            address: 'Jayadev Vihar, Bhubaneswar',
          ),
          severity: IncidentSeverity.medium,
          status: IncidentStatus.resolved,
          crashConfidence: 0.72,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incidentsListProvider.overrideWith((ref) => Future.value(sampleIncidents)),
          ],
          child: const MaterialApp(
            home: IncidentListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header, search bar, chips
      expect(find.text('Incident Registry'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('OPEN'), findsWidgets);
      expect(find.text('RESOLVED'), findsWidgets);

      // Verify incident cards rendered
      expect(find.text('inc-001'), findsOneWidget);
      expect(find.text('Station Square, Bhubaneswar'), findsOneWidget);
      expect(find.text('inc-002'), findsOneWidget);
      expect(find.text('Jayadev Vihar, Bhubaneswar'), findsOneWidget);

      // Verify FAB
      expect(find.text('Simulate Incident'), findsOneWidget);
    });
  });
}
