import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telephony/telephony.dart';
import 'contacts_provider.dart';
import '../services/emergency_sms_service.dart';
import '../models/dispatch_config.dart';
import '../models/dispatch_status.dart';
import '../models/emergency_state.dart';
import '../models/hardware_telemetry.dart';
import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/sensor_data.dart';
import '../services/backend_api.dart';
import '../services/crash_detection_service.dart';
import '../services/dispatch_service.dart';
import '../services/location_provider.dart';
import '../services/mock_backend_api.dart';
import '../services/real_backend_api.dart';
import '../services/real_time_data_service.dart';
import '../services/sensor_simulator.dart';
import '../services/state_machine_service.dart';
import '../services/ui_logger.dart';
import '../services/web_socket_service.dart';

/// Notifier to support mutable AppConfig in settings screen.
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier([AppConfig? initial]) : super(initial ?? const AppConfig());

  void updateConfig(AppConfig newConfig) {
    state = newConfig;
    UiLogger.log('App configuration updated');
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    UiLogger.log('Theme mode set to: ${mode.name}');
  }

  void setEnableSound(bool enabled) {
    state = state.copyWith(enableSound: enabled);
    UiLogger.log('Sound alerts enabled: $enabled');
  }

  void setEnableHaptics(bool enabled) {
    state = state.copyWith(enableHaptics: enabled);
    UiLogger.log('Haptic vibration enabled: $enabled');
  }

  void setApiBaseUrl(String url) {
    state = state.copyWith(apiBaseUrl: url);
    UiLogger.log('API Base URL set to: $url');
  }

  void setWsUrl(String url) {
    state = state.copyWith(
      wsUrl: url,
      dispatchConfig: state.dispatchConfig.copyWith(wsUrl: url),
    );
    UiLogger.log('WebSocket URL set to: $url');
  }

  void setMaxResponderDistance(double km) {
    state = state.copyWith(
      dispatchConfig: state.dispatchConfig.copyWith(maxResponderDistanceKm: km),
    );
    UiLogger.log('Max responder search radius set to: ${km.toStringAsFixed(1)}km');
  }

  void setDemoMode(bool enabled) {
    state = state.copyWith(demoMode: enabled);
    UiLogger.log('Demo mode set to: $enabled');
  }

  void setDemoDelay(int seconds) {
    state = state.copyWith(demoDelaySeconds: seconds);
  }

  void setShowDebugInfo(bool show) {
    state = state.copyWith(showDebugInfo: show);
  }

  void setGForceThreshold(double gForce) {
    state = state.copyWith(gForceThreshold: gForce);
  }

  void setAngularVelocityThreshold(double angularVelocity) {
    state = state.copyWith(angularVelocityThreshold: angularVelocity);
  }

  void setCountdownSeconds(int seconds) {
    state = state.copyWith(countdownSeconds: seconds);
  }

  void setUseRealHardware(bool enabled) {
    state = state.copyWith(useRealHardware: enabled);
    UiLogger.log('Real hardware mode: $enabled');
  }

  void setDeviceId(String id) {
    state = state.copyWith(deviceId: id);
    UiLogger.log('Device ID set to: $id');
  }

  void setDeviceToken(String token) {
    state = state.copyWith(deviceToken: token);
    UiLogger.log('Device token updated');
  }

  void resetToDefaults() {
    state = const AppConfig();
    UiLogger.log('Settings reset to defaults');
  }
}

/// Global AppConfig Notifier Provider
final appConfigNotifierProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});

/// Direct AppConfig Provider
final appConfigProvider = Provider<AppConfig>((ref) {
  return ref.watch(appConfigNotifierProvider);
});

/// Theme Mode Provider derived from AppConfig
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return appConfig.themeMode;
});

/// Dispatch configuration provider derived from AppConfig.
final dispatchConfigProvider = Provider<DispatchConfig>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return appConfig.dispatchConfig;
});

/// Backend API client provider.
/// REAL_HARDWARE: RealBackendApiClient (HTTP to Node.js backend)
/// SIMULATION:    MockBackendApiClient (in-memory)
final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useRealHardware) {
    final client = RealBackendApiClient(
      baseUrl: config.apiBaseUrl,
      deviceToken: config.deviceToken,
    );
    ref.onDispose(() => client.dispose());
    return client;
  }
  return MockBackendApiClient();
});

/// WebSocket service provider.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final config = ref.watch(dispatchConfigProvider);
  final ws = WebSocketService(config.wsUrl);
  ref.onDispose(() => ws.dispose());
  return ws;
});

/// Sensor Simulator Provider
final sensorSimulatorProvider = Provider<SensorSimulator>((ref) {
  final simulator = SensorSimulator();
  simulator.startNormalDriving();
  ref.onDispose(() => simulator.dispose());
  return simulator;
});

/// Sensor telemetry data stream provider
final sensorStreamProvider = StreamProvider<SensorData>((ref) {
  final simulator = ref.watch(sensorSimulatorProvider);
  return simulator.sensorStream;
});

/// Latest sensor telemetry provider.
/// REAL_HARDWARE: data from RealTimeDataService (socket.io sensor.update)
/// SIMULATION:    data from SensorSimulator
final currentSensorDataProvider = Provider<SensorData?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useRealHardware) {
    return ref.watch(realSensorStreamProvider).asData?.value;
  }
  return ref.watch(sensorStreamProvider).asData?.value;
});

/// Crash Detection Service Provider
final crashDetectionServiceProvider = Provider<CrashDetectionService>((ref) {
  final config = ref.watch(appConfigProvider);
  final service = CrashDetectionService(
    gForceThreshold: config.gForceThreshold,
    angularVelocityThreshold: config.angularVelocityThreshold,
  );
  final simulator = ref.watch(sensorSimulatorProvider);
  service.startListening(simulator.sensorStream);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Crash detection event stream provider
final detectionEventStreamProvider = StreamProvider<CrashDetectionEvent>((ref) {
  final service = ref.watch(crashDetectionServiceProvider);
  return service.crashStream;
});

/// Location Service Provider
final locationServiceProvider = Provider<LocationProvider>((ref) {
  final provider = LocationProvider();
  ref.onDispose(() => provider.dispose());
  return provider;
});

/// Location stream provider
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final provider = ref.watch(locationServiceProvider);
  return provider.locationStream;
});

/// Current Location Provider.
/// REAL_HARDWARE: data from RealTimeDataService (socket.io location.update)
/// SIMULATION:    data from LocationProvider (simulated route)
final currentLocationDataProvider = Provider<LocationData>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useRealHardware) {
    final real = ref.watch(realLocationStreamProvider).asData?.value;
    // Return real GPS or a placeholder (never hardcoded coords in real mode)
    return real ?? LocationData(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      address: 'Waiting for GPS fix...',
    );
  }
  final provider = ref.watch(locationServiceProvider);
  final asyncLoc = ref.watch(locationStreamProvider);
  return asyncLoc.asData?.value ?? provider.currentLocation;
});

/// Main DispatchService provider.
final dispatchServiceProvider = Provider<DispatchService>((ref) {
  final config = ref.watch(dispatchConfigProvider);
  final backendClient = ref.watch(backendApiClientProvider);
  final wsService = ref.watch(webSocketServiceProvider);

  final service = DispatchService(
    config: config,
    backendClient: backendClient,
    webSocketService: wsService,
  );

  ref.onDispose(() => service.dispose());
  return service;
});

/// State Machine Service Provider
final stateMachineServiceProvider = Provider<StateMachineService>((ref) {
  final config = ref.watch(appConfigProvider);
  final locationProvider = ref.watch(locationServiceProvider);
  final dispatchService = ref.watch(dispatchServiceProvider);
  final backendClient = ref.watch(backendApiClientProvider);

  // In REAL_HARDWARE mode, location comes from the hardware stream
  LocationData Function() getLocation;
  if (config.useRealHardware) {
    getLocation = () {
      final rtService = ref.read(realTimeDataServiceProvider);
      return rtService.lastLocation ??
          LocationData(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());
    };
  } else {
    getLocation = () => locationProvider.currentLocation;
  }

  final stateMachine = StateMachineService(
    initialCountdownSeconds: config.countdownSeconds,
    getCurrentLocation: getLocation,
    onDispatchTriggered: (incident) {
      backendClient.createIncident(incident);
      dispatchService.startDispatch(incident);
      ref.invalidate(incidentsListProvider);
    },
  );

  if (config.useRealHardware) {
    // REAL_HARDWARE: do NOT start simulator crash detection.
    // Instead transition to monitoring state and let hardware events drive it.
    stateMachine.startMonitoring(const Stream.empty());
    
    final rtService = ref.read(realTimeDataServiceProvider);
    final hwSub = rtService.hardwareStateStream.listen((hwState) {
      final current = stateMachine.currentState;
      if (hwState == current) return;
      
      switch (hwState) {
        case EmergencyState.countdown:
          final latestSensor = ref.read(realLatestSensorProvider);
          stateMachine.handleCrashDetected(CrashDetectionEvent(
              confidence: 1.0,
              peakGForce: latestSensor?.gForce ?? 0.0,
              peakAngularVelocity: latestSensor?.totalAngularVelocity ?? 0.0,
              timestamp: DateTime.now(),
              description: 'Hardware crash detected',
          ));
          break;
        case EmergencyState.confirmed:
          stateMachine.confirmEmergency();
          final contactsState = ref.read(contactsProvider);
          final loc = ref.read(realLatestLocationProvider);
          final telemetry = ref.read(realTimeDataServiceProvider).lastSensor;
          // Generate a unique emergency ID if none exists yet for this session
          final eId = 'INC-' + DateTime.now().millisecondsSinceEpoch.toString();
          
          emergencySmsService.sendEmergencySms(
            emergencyId: eId,
            contactsState: contactsState,
            location: loc,
            telemetry: telemetry,
          );
          break;
        case EmergencyState.cancelled:
          stateMachine.cancelEmergency();
          break;
        case EmergencyState.idle:
        case EmergencyState.resolved:
        case EmergencyState.monitoring:
        case EmergencyState.crashDetected:
        case EmergencyState.dispatched:
          if (hwState == EmergencyState.idle) stateMachine.reset();
          break;
      }
    });
    ref.onDispose(() => hwSub.cancel());
  } else {
    // SIMULATION: existing crash detection pipeline
    final crashService = ref.watch(crashDetectionServiceProvider);
    stateMachine.startMonitoring(crashService.crashStream);
  }

  // Sync state machine with dispatch lifecycle events
  final dispatchSub = dispatchService.dispatchStatusStream.listen((status) {
    if (status == DispatchStatus.completed) {
      stateMachine.resolveEmergency();
    } else if (status == DispatchStatus.cancelled || status == DispatchStatus.failed) {
      stateMachine.cancelEmergency();
    }
  });

  ref.onDispose(() {
    dispatchSub.cancel();
    stateMachine.dispose();
  });
  return stateMachine;
});

/// Alias provider for state machine
final stateMachineProvider = Provider<StateMachineService>((ref) {
  return ref.watch(stateMachineServiceProvider);
});

/// Stream provider for current emergency state
final emergencyStateProvider = StreamProvider<EmergencyState>((ref) {
  final service = ref.watch(stateMachineServiceProvider);
  return service.stateStream;
});

/// Stream provider for countdown value (seconds)
final countdownProvider = StreamProvider<int>((ref) {
  final service = ref.watch(stateMachineServiceProvider);
  return service.countdownStream;
});

/// Stream provider for reactive dispatch status updates in UI.
final dispatchStatusProvider = StreamProvider<DispatchStatus>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  return service.dispatchStatusStream;
});

/// Provider for current assigned primary responder (Ambulance).
final assignedResponderProvider = Provider<Responder?>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  ref.watch(responderLocationProvider);
  return service.assignedResponder;
});

/// Provider for current assigned trauma hospital.
final assignedHospitalProvider = Provider<Responder?>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  return service.assignedHospital;
});

/// Stream provider for real-time responder GPS movement updates.
final responderLocationProvider = StreamProvider<Responder>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  return service.responderLocationStream;
});

/// Stream provider for formatted dispatch and response log events.
final incidentUpdatesProvider = StreamProvider<String>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  return service.incidentUpdates;
});

/// Provider for the active incident object.
final currentIncidentProvider = Provider<Incident?>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  return service.currentIncident;
});

/// Future provider for all incidents list
final incidentsListProvider = FutureProvider<List<Incident>>((ref) async {
  final backendClient = ref.watch(backendApiClientProvider);
  // Also watch dispatch status so incident updates trigger list reloads
  ref.watch(dispatchStatusProvider);
  return await backendClient.getAllIncidents();
});

/// Provider for list of active incidents (open, dispatched, inProgress)
final activeIncidentsProvider = FutureProvider<List<Incident>>((ref) async {
  final incidents = await ref.watch(incidentsListProvider.future);
  return incidents.where((inc) =>
      inc.status == IncidentStatus.open ||
      inc.status == IncidentStatus.dispatched ||
      inc.status == IncidentStatus.inProgress).toList();
});

/// FutureProvider family to resolve the specific assigned ambulance and hospital for any incident.
final incidentRespondersProvider = FutureProvider.family<
    ({Responder? ambulance, Responder? hospital}), String>((ref, incidentId) async {
  final backendClient = ref.watch(backendApiClientProvider);
  final incident = await backendClient.getIncident(incidentId);

  if (incident == null) {
    return (ambulance: null, hospital: null);
  }

  Responder? ambulance;
  Responder? hospital;

  if (incident.assignedResponderId != null) {
    final ambulances = await backendClient.findNearestResponders(
      incident.location,
      radiusKm: 50.0,
      type: ResponderType.ambulance,
    );
    ambulance = ambulances.where((a) => a.id == incident.assignedResponderId).firstOrNull;
  }

  if (incident.assignedHospitalId != null) {
    final hospitals = await backendClient.findNearestResponders(
      incident.location,
      radiusKm: 50.0,
      type: ResponderType.hospital,
    );
    hospital = hospitals.where((h) => h.id == incident.assignedHospitalId).firstOrNull;
  }

  // Fallback to active live assigned providers if this is the active live incident
  final liveIncident = ref.watch(currentIncidentProvider);
  if (liveIncident?.id == incidentId) {
    ambulance ??= ref.watch(assignedResponderProvider);
    hospital ??= ref.watch(assignedHospitalProvider);
  }

  return (ambulance: ambulance, hospital: hospital);
});

/// UI Logs Provider
final uiLogsProvider = Provider<List<String>>((ref) {
  return UiLogger.logs;
});

// ═══════════════════════════════════════════════════════════════════════════
// REAL HARDWARE PROVIDERS
// Active only when AppConfig.useRealHardware = true.
// Simulation providers above are unaffected.
// ═══════════════════════════════════════════════════════════════════════════

/// Core real-time data service (Socket.IO client).
/// Auto-connects when useRealHardware = true.
final realTimeDataServiceProvider = Provider<RealTimeDataService>((ref) {
  final config = ref.watch(appConfigProvider);
  final service = RealTimeDataService(
    serverUrl: config.wsUrl,
    deviceId: config.deviceId,
  );
  if (config.useRealHardware) {
    service.connect();
  }
  ref.onDispose(() => service.dispose());
  return service;
});

/// Real sensor data stream from the helmet via Socket.IO.
final realSensorStreamProvider = StreamProvider<SensorData>((ref) {
  final service = ref.watch(realTimeDataServiceProvider);
  return service.sensorStream;
});

/// Real GPS location stream from the helmet via Socket.IO.
final realLocationStreamProvider = StreamProvider<LocationData>((ref) {
  final service = ref.watch(realTimeDataServiceProvider);
  return service.locationStream;
});

/// Hardware emergency state stream.
/// Maps NORMAL/CRASH_PENDING/EMERGENCY_CONFIRMED/CANCELLED → EmergencyState.
final realHardwareStateStreamProvider = StreamProvider<EmergencyState>((ref) {
  final service = ref.watch(realTimeDataServiceProvider);
  return service.hardwareStateStream;
});

/// Real incident stream — fired when backend creates an incident on EMERGENCY_CONFIRMED.
final realIncidentStreamProvider = StreamProvider<Incident>((ref) {
  final service = ref.watch(realTimeDataServiceProvider);
  return service.incidentStream;
});

/// Socket.IO connection status stream.
final realConnectionStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(realTimeDataServiceProvider);
  return service.connectionStream;
});

/// Device (helmet) online/stale/offline status stream.
final deviceStatusStreamProvider = StreamProvider<DeviceConnectionStatus>((ref) {
  final service = ref.watch(realTimeDataServiceProvider);
  return service.deviceStatusStream;
});

/// Sync accessor for current device status.
final currentDeviceStatusProvider = Provider<DeviceConnectionStatus>((ref) {
  final asyncStatus = ref.watch(deviceStatusStreamProvider);
  return asyncStatus.asData?.value ??
      ref.watch(realTimeDataServiceProvider).deviceStatus;
});

/// Whether the Socket.IO connection to the backend is active.
final isSocketConnectedProvider = Provider<bool>((ref) {
  final asyncConn = ref.watch(realConnectionStatusProvider);
  return asyncConn.asData?.value ??
      ref.watch(realTimeDataServiceProvider).isConnected;
});

/// The last received sensor data (sync snapshot).
final realLatestSensorProvider = Provider<SensorData?>((ref) {
  return ref.watch(realSensorStreamProvider).asData?.value;
});

/// The last received GPS location (sync snapshot).
final realLatestLocationProvider = Provider<LocationData?>((ref) {
  return ref.watch(realLocationStreamProvider).asData?.value;
});
