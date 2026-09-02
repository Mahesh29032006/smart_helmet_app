import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/models/location_data.dart';
import 'package:emergency_response_app/core/services/location_provider.dart';

void main() {
  group('LocationProvider & Coordinates Math Tests', () {
    late LocationProvider provider;

    setUp(() {
      provider = LocationProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('1. Initial location is initialized with valid coordinates', () {
      final loc = provider.currentLocation;
      expect(loc.latitude, greaterThan(0.0));
      expect(loc.longitude, greaterThan(0.0));
      expect(loc.address, isNotNull);
    });

    test('2. Updating location updates stream and current property', () async {
      final updates = <LocationData>[];
      final sub = provider.locationStream.listen(updates.add);

      final newLoc = LocationData(
        latitude: 20.3500,
        longitude: 85.8200,
        timestamp: DateTime.now(),
        address: 'New Location Point',
      );

      provider.updateLocation(newLoc);
      expect(provider.currentLocation.latitude, 20.3500);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(updates.isNotEmpty, isTrue);
      expect(updates.last.address, 'New Location Point');

      await sub.cancel();
    });

    test('3. Calculate distance accurately with Haversine formula', () {
      final p1 = LocationData(
        latitude: 20.2961,
        longitude: 85.8245,
        timestamp: DateTime.now(),
      );

      final p2 = LocationData(
        latitude: 20.3015,
        longitude: 85.8290,
        timestamp: DateTime.now(),
      );

      final distanceKm = calculateDistance(p1, p2);
      expect(distanceKm, greaterThan(0.5));
      expect(distanceKm, lessThan(1.5));
    });

    test('4. Calculate ETA accurately based on speed', () {
      final p1 = LocationData(
        latitude: 20.2961,
        longitude: 85.8245,
        timestamp: DateTime.now(),
      );

      final p2 = LocationData(
        latitude: 20.3500,
        longitude: 85.8245,
        timestamp: DateTime.now(),
      );

      final eta = calculateETA(p1, p2, avgSpeedKmph: 60.0);
      expect(eta, greaterThan(0.0));
      expect(eta, closeTo(6.0, 2.0));
    });
  });
}
