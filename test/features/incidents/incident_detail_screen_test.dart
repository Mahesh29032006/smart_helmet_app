import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/incidents/screens/incident_detail_screen.dart';

void main() {
  group('IncidentDetailScreen Widget Tests', () {
    testWidgets('Incident detail shows full info, sensor evidence, and timeline', (tester) async {
      final sampleIncident = Incident(
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
        notes: 'High acceleration delta impact',
        metadata: {
          'peakGForce': 4.8,
          'peakAngularVelocity': 3.6,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incidentsListProvider.overrideWith((ref) => Future.value([sampleIncident])),
          ],
          child: const MaterialApp(
            home: IncidentDetailScreen(id: 'inc-001'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Incident inc-001'), findsOneWidget);
      expect(find.text('Station Square, Bhubaneswar'), findsOneWidget);
      expect(find.text('Sensor Evidence & Telemetry'), findsOneWidget);
      expect(find.text('Peak G-Force'), findsOneWidget);
      expect(find.text('4.8 G'), findsOneWidget);
      expect(find.text('Incident Timeline & Audit Trail'), findsOneWidget);
      expect(find.text('Dispatch Units'), findsOneWidget);
    });
  });
}
