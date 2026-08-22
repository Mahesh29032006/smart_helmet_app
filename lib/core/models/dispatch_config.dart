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
    this.wsUrl = 'ws://localhost:5000/socket.io',
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

  const AppConfig({
    this.appName = 'RescueLink Emergency Response',
    this.apiBaseUrl = 'http://localhost:5000/api/v1',
    this.wsUrl = 'ws://localhost:5000/socket.io',
    this.isDebug = true,
    this.dispatchConfig = const DispatchConfig(),
  });
}
