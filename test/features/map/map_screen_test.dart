import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/models/responder.dart';
import 'package:emergency_response_app/core/models/responder_status.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/features/map/screens/map_screen.dart';

void main() {
  group('MapScreen Widget Tests', () {
    testWidgets('Map shows markers and live dispatch info HUD', (tester) async {
      final sampleLoc = LocationData(
        latitude: 20.2961,
        longitude: 85.8245,
        timestamp: DateTime.now(),
        address: 'Saheed Nagar, Bhubaneswar',
      );

      final sampleAmbulance = Responder(
        id: 'amb-01',
        name: 'Ambulance A1 (Advance Life Support)',
        type: ResponderType.ambulance,
        status: ResponderStatus.enRoute,
        location: LocationData(
          latitude: 20.3015,
          longitude: 85.8290,
          timestamp: DateTime.now(),
        ),
        phone: '+91-9876543210',
        distanceKm: 0.8,
        etaMinutes: 2.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLocationDataProvider.overrideWithValue(sampleLoc),
            assignedResponderProvider.overrideWithValue(sampleAmbulance),
          ],
          child: const MaterialApp(
            home: MapScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Real-Time Emergency Map'), findsOneWidget);
      expect(find.text('Ambulance A1 (Advance Life Support)'), findsOneWidget);
      expect(find.text('EN ROUTE'), findsWidgets);
      expect(find.text('0.8 km'), findsOneWidget);
      expect(find.text('ETA: ~2 min'), findsOneWidget);
    });
  });
}
