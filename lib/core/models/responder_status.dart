/// Represents the operational status of an emergency responder unit (Ambulance, Hospital, Fire, Police).
enum ResponderStatus {
  /// Responder is online, on duty, and ready for dispatch.
  available,

  /// Responder has been assigned an incident and pending acknowledgement/deployment.
  dispatched,

  /// Responder is actively driving/traveling to the incident scene.
  enRoute,

  /// Responder is on-site at the incident scene.
  arrived,

  /// Responder is conveying patient(s) to a medical facility.
  transporting,

  /// Responder is offline, out of service, or undergoing maintenance.
  unavailable;

  /// Returns true if the responder is free to take a new dispatch.
  bool get isAvailable => this == ResponderStatus.available;

  /// Returns true if the responder is currently engaged with an active incident.
  bool get isBusy =>
      this == ResponderStatus.dispatched ||
      this == ResponderStatus.enRoute ||
      this == ResponderStatus.arrived ||
      this == ResponderStatus.transporting;

  /// Returns a user-friendly display name.
  String get displayName {
    switch (this) {
      case ResponderStatus.available:
        return 'Available';
      case ResponderStatus.dispatched:
        return 'Dispatched';
      case ResponderStatus.enRoute:
        return 'En Route';
      case ResponderStatus.arrived:
        return 'Arrived';
      case ResponderStatus.transporting:
        return 'Transporting';
      case ResponderStatus.unavailable:
        return 'Unavailable';
    }
  }
}
