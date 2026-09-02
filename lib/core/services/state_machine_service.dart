import 'dart:async';
import '../models/emergency_state.dart';
import '../models/incident.dart';
import '../models/location_data.dart';
import 'crash_detection_service.dart';

/// Manages emergency lifecycle transitions, user countdown, and auto-dispatch triggers.
class StateMachineService {
  EmergencyState _state = EmergencyState.idle;
  int _countdownSeconds;
  final int initialCountdownSeconds;
  Timer? _countdownTimer;

  final _stateController = StreamController<EmergencyState>.broadcast();
  final _countdownController = StreamController<int>.broadcast();
  StreamSubscription<CrashDetectionEvent>? _crashSubscription;

  void Function(Incident incident)? onDispatchTriggered;
  LocationData Function()? getCurrentLocation;

  StateMachineService({
    this.initialCountdownSeconds = 15,
    this.onDispatchTriggered,
    this.getCurrentLocation,
  }) : _countdownSeconds = initialCountdownSeconds;

  EmergencyState get currentState => _state;
  int get countdownSeconds => _countdownSeconds;
  Stream<EmergencyState> get stateStream => _stateController.stream;
  Stream<int> get countdownStream => _countdownController.stream;

  void startMonitoring(Stream<CrashDetectionEvent> crashStream) {
    _state = EmergencyState.monitoring;
    Future.microtask(() => _stateController.add(_state));

    _crashSubscription?.cancel();
    _crashSubscription = crashStream.listen((event) {
      handleCrashDetected(event);
    });
  }

  void handleCrashDetected(CrashDetectionEvent event) {
    if (_state.isActiveEmergency) return;

    _state = EmergencyState.crashDetected;
    _stateController.add(_state);
    startCountdown();
  }

  void startCountdown() {
    _state = EmergencyState.countdown;
    _countdownSeconds = initialCountdownSeconds;
    _stateController.add(_state);
    _countdownController.add(_countdownSeconds);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        _countdownSeconds--;
        _countdownController.add(_countdownSeconds);
      } else {
        _countdownSeconds = 0;
        _countdownController.add(0);
        timer.cancel();
        confirmEmergency();
      }
    });
  }

  void cancelEmergency() {
    _countdownTimer?.cancel();
    _state = EmergencyState.cancelled;
    _stateController.add(_state);
  }

  void confirmEmergency() {
    _countdownTimer?.cancel();
    _state = EmergencyState.confirmed;
    _stateController.add(_state);

    // Transition to dispatched
    transitionToDispatched();
  }

  void transitionToDispatched() {
    _state = EmergencyState.dispatched;
    _stateController.add(_state);

    final location = getCurrentLocation != null
        ? getCurrentLocation!()
        : LocationData(
            latitude: 20.2961,
            longitude: 85.8245,
            timestamp: DateTime.now(),
          );

    final incident = Incident(
      id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      location: location,
      severity: IncidentSeverity.critical,
      status: IncidentStatus.open,
    );

    if (onDispatchTriggered != null) {
      onDispatchTriggered!(incident);
    }
  }

  void resolveEmergency() {
    _countdownTimer?.cancel();
    _state = EmergencyState.resolved;
    _stateController.add(_state);
  }

  void reset() {
    _countdownTimer?.cancel();
    _state = EmergencyState.idle;
    _countdownSeconds = initialCountdownSeconds;
    _stateController.add(_state);
  }

  void dispose() {
    _countdownTimer?.cancel();
    _crashSubscription?.cancel();
    _stateController.close();
    _countdownController.close();
  }
}
