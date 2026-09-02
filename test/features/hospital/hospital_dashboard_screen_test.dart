import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/models/responder.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/hospital/screens/hospital_dashboard_screen.dart';

void main() {
  group('HospitalDashboardScreen Widget Tests', () {
    testWidgets('Hospital dashboard shows capacity stats and incoming patient cards', (tester) async {
      final sampleIncident = Incident(
        id: 'inc-999',
        timestamp: DateTime.now(),
        location: LocationData(
          latitude: 20.2961,
          longitude: 85.8245,
          timestamp: DateTime.now(),
          address: 'Station Square, Bhubaneswar',
        ),
        severity: IncidentSeverity.critical,
        status: IncidentStatus.dispatched,
        etaMinutes: 4.0,
      );

      final sampleHospital = Responder(
        id: 'hosp-01',
        name: 'City Trauma Centre & Multi-speciality',
        type: ResponderType.hospital,
        status: ResponderStatus.available,
        location: LocationData(
          latitude: 20.3120,
          longitude: 85.8390,
          timestamp: DateTime.now(),
        ),
        phone: '+91-674-2500100',
        traumaCapability: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeIncidentsProvider.overrideWith((ref) => Future.value([sampleIncident])),
            assignedHospitalProvider.overrideWithValue(sampleHospital),
          ],
          child: const MaterialApp(
            home: HospitalDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hospital Emergency Department'), findsOneWidget);
      expect(find.text('City Trauma Centre & Multi-speciality'), findsOneWidget);
      expect(find.text('TRAUMA BEDS'), findsOneWidget);
      expect(find.text('ICU BAYS'), findsOneWidget);
      expect(find.text('Incoming Trauma Patients'), findsOneWidget);
      expect(find.text('Patient #999'), findsOneWidget);
      expect(find.text('BED PREPARING'), findsWidgets);
    });
  });
}
