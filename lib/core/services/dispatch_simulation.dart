import 'dart:async';
import '../models/dispatch_simulation_config.dart';
import '../models/dispatch_status.dart';
import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/responder_status.dart';

/// Simulates the realistic real-time lifecycle and telemetry movement of an emergency dispatch.
class DispatchSimulation {
  final DispatchSimulationConfig config;

  Timer? _stageTimer;
  Timer? _movementTimer;
  bool _isRunning = false;

  final void Function(DispatchStatus status) onStatusChanged;
  final void Function(Responder responder) onLocationUpdated;
  final void Function(String message)? onLog;

  DispatchSimulation({
    required this.config,
    required this.onStatusChanged,
    required this.onLocationUpdated,
    this.onLog,
  });

  bool get isRunning => _isRunning;

  /// Starts the full automated dispatch simulation workflow.
  Future<void> runSimulation({
    required Incident incident,
    required Responder responder,
    required Responder? hospital,
  }) async {
    cancel();
    _isRunning = true;

    // Stage 1: Searching for responders
    onLog?.call(
        '[Dispatch] Searching for responders near ${incident.location.latitude.toStringAsFixed(4)}, ${incident.location.longitude.toStringAsFixed(4)}');
    onStatusChanged(DispatchStatus.searching);

    await _wait(config.searchDuration);
    if (!_isRunning) return;

    // Stage 2: Dispatched
    final distanceKm = calculateDistance(responder.location, incident.location);
    final etaMin = calculateETA(responder.location, incident.location);
    onLog?.call(
        '[Dispatch] Found: ${responder.name} (${distanceKm.toStringAsFixed(1)}km away)');
    onLog?.call('[Dispatch] Dispatch sent to ${responder.name}');

    var currentResponder = responder.copyWith(
      status: ResponderStatus.dispatched,
      distanceKm: distanceKm,
      etaMinutes: etaMin,
      assignedIncidentId: incident.id,
    );
    onStatusChanged(DispatchStatus.dispatched);
    onLocationUpdated(currentResponder);

    await _wait(config.acceptDuration);
    if (!_isRunning) return;

    // Stage 3: Acknowledged / Accepted
    if (!config.autoAccept) {
      onLog?.call('[Dispatch] Waiting for manual responder acknowledgement...');
      return;
    }

    onLog?.call(
        '[Dispatch] ${responder.name} accepted (ETA: ${etaMin.toStringAsFixed(0)} min)');
    currentResponder =
        currentResponder.copyWith(status: ResponderStatus.dispatched);
    onStatusChanged(DispatchStatus.acknowledged);

    await _wait(config.acceptDuration);
    if (!_isRunning) return;

    // Stage 4: En Route to Scene
    onLog?.call('[Dispatch] ${responder.name} en route');
    currentResponder =
        currentResponder.copyWith(status: ResponderStatus.enRoute);
    onStatusChanged(DispatchStatus.enRoute);

    if (config.autoMove) {
      await _simulateMovement(
        from: responder.location,
        to: incident.location,
        totalDuration: config.enRouteDuration,
        onUpdate: (loc, remainingEta, remainingDist) {
          currentResponder = currentResponder.copyWith(
            location: loc,
            distanceKm: remainingDist,
            etaMinutes: remainingEta,
          );
          onLocationUpdated(currentResponder);
        },
      );
    } else {
      await _wait(config.enRouteDuration);
    }
    if (!_isRunning) return;

    // Stage 5: Arrived at Scene
    onLog?.call('[Dispatch] ${responder.name} arrived at scene');
    currentResponder = currentResponder.copyWith(
      status: ResponderStatus.arrived,
      location: incident.location,
      distanceKm: 0.0,
      etaMinutes: 0.0,
    );
    onStatusChanged(DispatchStatus.arrived);
    onLocationUpdated(currentResponder);

    await _wait(config.arriveDuration);
    if (!_isRunning) return;

    // Stage 6: Transporting Patient to Hospital
    final hospitalDest = hospital?.location ??
        LocationData(
          latitude: incident.location.latitude + 0.02,
          longitude: incident.location.longitude + 0.02,
          timestamp: DateTime.now(),
          address: 'General Emergency Hospital',
        );
    final hospitalName = hospital?.name ?? 'City Trauma Centre';

    onLog?.call(
        '[Dispatch] Patient loaded into ambulance. Transporting to $hospitalName');
    currentResponder =
        currentResponder.copyWith(status: ResponderStatus.transporting);
    onStatusChanged(DispatchStatus.transporting);

    if (config.autoMove) {
      await _simulateMovement(
        from: incident.location,
        to: hospitalDest,
        totalDuration: config.transportDuration,
        onUpdate: (loc, remainingEta, remainingDist) {
          currentResponder = currentResponder.copyWith(
            location: loc,
            distanceKm: remainingDist,
            etaMinutes: remainingEta,
          );
          onLocationUpdated(currentResponder);
        },
      );
    } else {
      await _wait(config.transportDuration);
    }
    if (!_isRunning) return;

    // Stage 7: Delivered to Hospital
    onLog?.call('[Dispatch] Patient transported to $hospitalName');
    currentResponder = currentResponder.copyWith(
      status: ResponderStatus.available,
      location: hospitalDest,
      distanceKm: 0.0,
      etaMinutes: 0.0,
    );
    onStatusChanged(DispatchStatus.delivered);
    onLocationUpdated(currentResponder);

    await _wait(config.deliverDuration);
    if (!_isRunning) return;

    // Stage 8: Completed
    onLog?.call('[Dispatch] Incident resolved');
    onStatusChanged(DispatchStatus.completed);
    _isRunning = false;
  }

  /// Interpolates coordinates smoothly between from and to points over [totalDuration].
  Future<void> _simulateMovement({
    required LocationData from,
    required LocationData to,
    required Duration totalDuration,
    required void Function(LocationData location, double remainingEtaMinutes,
            double remainingDistKm)
        onUpdate,
  }) async {
    final completer = Completer<void>();
    final intervalMs = config.movementUpdateInterval.inMilliseconds;
    final totalSteps =
        (totalDuration.inMilliseconds / intervalMs).clamp(2, 50).toInt();
    int currentStep = 0;

    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(config.movementUpdateInterval, (timer) {
      if (!_isRunning) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }

      currentStep++;
      final fraction = (currentStep / totalSteps).clamp(0.0, 1.0);
      final currentLocation = interpolateLocation(from, to, fraction);
      final remainingDist = calculateDistance(currentLocation, to);
      final remainingEta = calculateETA(currentLocation, to);

      onUpdate(currentLocation, remainingEta, remainingDist);

      if (currentStep >= totalSteps) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  Future<void> _wait(Duration duration) async {
    final completer = Completer<void>();
    _stageTimer?.cancel();
    _stageTimer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  /// Cancels any active simulation timers and stops progression.
  void cancel() {
    _isRunning = false;
    _stageTimer?.cancel();
    _movementTimer?.cancel();
  }

  void dispose() {
    cancel();
  }
}
