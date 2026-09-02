import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/incident.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/models/responder.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/ambulance/screens/ambulance_dashboard_screen.dart';

void main() {
  group('AmbulanceDashboardScreen Widget Tests', () {
    testWidgets('Ambulance dashboard shows assigned dispatch, route, and status buttons', (tester) async {
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
        status: IncidentStatus.dispatched,
      );

      final sampleAmbulance = Responder(
        id: 'amb-01',
        name: 'Ambulance A1 (Advance Life Support)',
        type: ResponderType.ambulance,
        status: ResponderStatus.dispatched,
        location: LocationData(
          latitude: 20.3015,
          longitude: 85.8290,
          timestamp: DateTime.now(),
        ),
        phone: '+91-9876543210',
        vehicleNumber: 'OD-02-EM-1081',
        distanceKm: 1.2,
        etaMinutes: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentIncidentProvider.overrideWithValue(sampleIncident),
            assignedResponderProvider.overrideWithValue(sampleAmbulance),
          ],
          child: const MaterialApp(
            home: AmbulanceDashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Ambulance Terminal (ALS-1081)'), findsOneWidget);
      expect(find.text('Assigned Emergency Dispatch'), findsOneWidget);
      expect(find.text('Dispatch for inc-001'), findsOneWidget);
      expect(find.text('Station Square, Bhubaneswar'), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('EN ROUTE'), findsWidgets);
      expect(find.text('ARRIVED'), findsOneWidget);
      expect(find.text('TRANSPORTING'), findsOneWidget);
    });
  });
}
