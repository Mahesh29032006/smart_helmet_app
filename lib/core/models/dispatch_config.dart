import 'package:flutter/material.dart';

import 'dispatch_simulation_config.dart';

/// Configuration for emergency dispatch operations.
class DispatchConfig {
  /// Maximum duration to search for candidate responders before failing/escalating.
  final Duration searchTimeout;

  /// Maximum radius (in km) to query candidate responders around the incident scene.
  final double maxResponderDistanceKm;

  /// Default average speed (in km/h) for ambulances in urban emergency transit.
  final double ambulanceAvgSpeedKmph;

  /// Flag to indicate whether to run in mock simulation mode or connect to live backend.
  final bool useSimulation;

  /// WebSocket URL for real-time Socket.IO / event gateway.
  final String wsUrl;

  /// Flag to indicate whether the simulation automatically steps through each lifecycle stage.
  final bool autoProgressSimulation;

  /// Detailed timing and progression config for simulation mode.
  final DispatchSimulationConfig simulationConfig;

  const DispatchConfig({
    this.searchTimeout = const Duration(seconds: 5),
    this.maxResponderDistanceKm = 10.0,
    this.ambulanceAvgSpeedKmph = 40.0,
    this.useSimulation = true,
    this.wsUrl = 'ws://172.21.73.191:5001/socket.io',
    this.autoProgressSimulation = true,
    this.simulationConfig = const DispatchSimulationConfig(),
  });

  DispatchConfig copyWith({
    Duration? searchTimeout,
    double? maxResponderDistanceKm,
    double? ambulanceAvgSpeedKmph,
    bool? useSimulation,
    String? wsUrl,
    bool? autoProgressSimulation,
    DispatchSimulationConfig? simulationConfig,
  }) {
    return DispatchConfig(
      searchTimeout: searchTimeout ?? this.searchTimeout,
      maxResponderDistanceKm:
          maxResponderDistanceKm ?? this.maxResponderDistanceKm,
      ambulanceAvgSpeedKmph:
          ambulanceAvgSpeedKmph ?? this.ambulanceAvgSpeedKmph,
      useSimulation: useSimulation ?? this.useSimulation,
      wsUrl: wsUrl ?? this.wsUrl,
      autoProgressSimulation:
          autoProgressSimulation ?? this.autoProgressSimulation,
      simulationConfig: simulationConfig ?? this.simulationConfig,
    );
  }
}

/// Global Application Configuration
class AppConfig {
  final String appName;
  final String apiBaseUrl;
  final String wsUrl;
  final bool isDebug;
  final DispatchConfig dispatchConfig;
  final bool demoMode;
  final int demoDelaySeconds;
  final bool showDebugInfo;
  final double gForceThreshold;
  final double angularVelocityThreshold;
  final int countdownSeconds;
  final ThemeMode themeMode;
  final bool enableSound;
  final bool enableHaptics;

  // ─── Real Hardware Mode ──────────────────────────────────────────────────
  /// When true: use real helmet hardware via backend Socket.IO.
  /// When false: use existing SensorSimulator + MockBackendApiClient.
  final bool useRealHardware;

  /// Device ID to identify this helmet (matches ESP32 deviceId).
  final String deviceId;

  /// API token sent as X-Device-Token / used to authenticate Socket.IO connection.
  final String deviceToken;

  const AppConfig({
    this.appName = 'RescueLink Emergency Response',
    // Change defaults from localhost to your IP:
this.apiBaseUrl = 'http://172.21.73.191:5001/api/v1',
this.wsUrl = 'http://172.21.73.191:5001',
    this.isDebug = true,
    this.dispatchConfig = const DispatchConfig(),
    this.demoMode = false,
    this.demoDelaySeconds = 5,
    this.showDebugInfo = true,
    this.gForceThreshold = 3.0,
    this.angularVelocityThreshold = 2.5,
    this.countdownSeconds = 10,
    this.themeMode = ThemeMode.system,
    this.enableSound = true,
    this.enableHaptics = true,
    this.useRealHardware = false,
    this.deviceId = 'helmet-01',
    this.deviceToken = 'change-me',
  });

  AppConfig copyWith({
    String? appName,
    String? apiBaseUrl,
    String? wsUrl,
    bool? isDebug,
    DispatchConfig? dispatchConfig,
    bool? demoMode,
    int? demoDelaySeconds,
    bool? showDebugInfo,
    double? gForceThreshold,
    double? angularVelocityThreshold,
    int? countdownSeconds,
    ThemeMode? themeMode,
    bool? enableSound,
    bool? enableHaptics,
    bool? useRealHardware,
    String? deviceId,
    String? deviceToken,
  }) {
    return AppConfig(
      appName: appName ?? this.appName,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      wsUrl: wsUrl ?? this.wsUrl,
      isDebug: isDebug ?? this.isDebug,
      dispatchConfig: dispatchConfig ?? this.dispatchConfig,
      demoMode: demoMode ?? this.demoMode,
      demoDelaySeconds: demoDelaySeconds ?? this.demoDelaySeconds,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      gForceThreshold: gForceThreshold ?? this.gForceThreshold,
      angularVelocityThreshold:
          angularVelocityThreshold ?? this.angularVelocityThreshold,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      themeMode: themeMode ?? this.themeMode,
      enableSound: enableSound ?? this.enableSound,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      useRealHardware: useRealHardware ?? this.useRealHardware,
      deviceId: deviceId ?? this.deviceId,
      deviceToken: deviceToken ?? this.deviceToken,
    );
  }
}

