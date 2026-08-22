/// Configuration parameters for simulated emergency dispatch progression.
class DispatchSimulationConfig {
  /// Time spent searching for responders before dispatching.
  final Duration searchDuration;

  /// Time between dispatching alert and responder accepting.
  final Duration acceptDuration;

  /// Time spent traveling from station to incident scene.
  final Duration enRouteDuration;

  /// Time spent on scene for triage and patient stabilization.
  final Duration arriveDuration;

  /// Time spent transporting patient to destination medical facility.
  final Duration transportDuration;

  /// Time spent admitting patient at emergency department.
  final Duration deliverDuration;

  /// Time spent finalizing paperwork and closing incident.
  final Duration completeDuration;

  /// Whether the responder automatically accepts the incoming dispatch.
  final bool autoAccept;

  /// Whether GPS coordinates automatically interpolate along route.
  final bool autoMove;

  /// Frequency of GPS coordinate updates during travel (in milliseconds).
  final Duration movementUpdateInterval;

  const DispatchSimulationConfig({
    this.searchDuration = const Duration(seconds: 2),
    this.acceptDuration = const Duration(seconds: 1),
    this.enRouteDuration = const Duration(seconds: 2),
    this.arriveDuration = const Duration(seconds: 1),
    this.transportDuration = const Duration(seconds: 2),
    this.deliverDuration = const Duration(seconds: 1),
    this.completeDuration = const Duration(seconds: 1),
    this.autoAccept = true,
    this.autoMove = true,
    this.movementUpdateInterval = const Duration(milliseconds: 250),
  });

  DispatchSimulationConfig copyWith({
    Duration? searchDuration,
    Duration? acceptDuration,
    Duration? enRouteDuration,
    Duration? arriveDuration,
    Duration? transportDuration,
    Duration? deliverDuration,
    Duration? completeDuration,
    bool? autoAccept,
    bool? autoMove,
    Duration? movementUpdateInterval,
  }) {
    return DispatchSimulationConfig(
      searchDuration: searchDuration ?? this.searchDuration,
      acceptDuration: acceptDuration ?? this.acceptDuration,
      enRouteDuration: enRouteDuration ?? this.enRouteDuration,
      arriveDuration: arriveDuration ?? this.arriveDuration,
      transportDuration: transportDuration ?? this.transportDuration,
      deliverDuration: deliverDuration ?? this.deliverDuration,
      completeDuration: completeDuration ?? this.completeDuration,
      autoAccept: autoAccept ?? this.autoAccept,
      autoMove: autoMove ?? this.autoMove,
      movementUpdateInterval:
          movementUpdateInterval ?? this.movementUpdateInterval,
    );
  }
}
