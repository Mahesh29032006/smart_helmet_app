import 'dart:async';
import '../models/location_data.dart';

/// Provides real-time GPS locations and caching with support for simulated movement.
class LocationProvider {
  LocationData _currentLocation;
  final _locationController = StreamController<LocationData>.broadcast();
  Timer? _simulationTimer;

  LocationProvider({LocationData? initialLocation})
      : _currentLocation = initialLocation ??
            LocationData(
              latitude: 20.2961,
              longitude: 85.8245,
              timestamp: DateTime.now(),
              address: 'Saheed Nagar, Bhubaneswar, Odisha',
            );

  LocationData get currentLocation => _currentLocation;
  Stream<LocationData> get locationStream => _locationController.stream;

  void updateLocation(LocationData newLocation) {
    _currentLocation = newLocation;
    _locationController.add(newLocation);
  }

  void startRouteSimulation(List<LocationData> waypoints, {Duration interval = const Duration(seconds: 1)}) {
    _simulationTimer?.cancel();
    if (waypoints.isEmpty) return;

    int index = 0;
    _simulationTimer = Timer.periodic(interval, (timer) {
      if (index >= waypoints.length) {
        timer.cancel();
        return;
      }
      updateLocation(waypoints[index]);
      index++;
    });
  }

  void dispose() {
    _simulationTimer?.cancel();
    _locationController.close();
  }
}
