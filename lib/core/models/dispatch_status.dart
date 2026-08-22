/// Represents the lifecycle states of an emergency dispatch operation.
enum DispatchStatus {
  /// No active dispatch operation.
  idle,

  /// Searching and querying for available responders nearby.
  searching,

  /// Nearest responder assigned to the incident.
  dispatched,

  /// Responder has acknowledged and accepted the dispatch assignment.
  acknowledged,

  /// Responder is currently traveling towards the incident scene.
  enRoute,

  /// Responder has arrived on-site at the incident scene.
  arrived,

  /// Patient has been stabilized and is being transported in the ambulance.
  transporting,

  /// Patient has been delivered safely to the destination hospital/trauma center.
  delivered,

  /// Emergency response completed and incident marked as resolved.
  completed,

  /// Dispatch was explicitly cancelled by user or operator.
  cancelled,

  /// Dispatch failed (e.g. no responders available or connection timeout).
  failed;

  /// Returns true if the dispatch has reached a final/terminal state.
  bool get isTerminal =>
      this == DispatchStatus.completed ||
      this == DispatchStatus.cancelled ||
      this == DispatchStatus.failed;

  /// Returns true if the dispatch is currently active and in progress.
  bool get isActive =>
      this != DispatchStatus.idle &&
      this != DispatchStatus.completed &&
      this != DispatchStatus.cancelled &&
      this != DispatchStatus.failed;

  /// Returns true if the dispatch can still be cancelled.
  bool get canCancel => isActive;

  /// Returns a user-friendly display name for the status.
  String get displayName {
    switch (this) {
      case DispatchStatus.idle:
        return 'Idle';
      case DispatchStatus.searching:
        return 'Searching Responders';
      case DispatchStatus.dispatched:
        return 'Dispatched';
      case DispatchStatus.acknowledged:
        return 'Acknowledged';
      case DispatchStatus.enRoute:
        return 'En Route';
      case DispatchStatus.arrived:
        return 'Arrived at Scene';
      case DispatchStatus.transporting:
        return 'Transporting Patient';
      case DispatchStatus.delivered:
        return 'Delivered to Hospital';
      case DispatchStatus.completed:
        return 'Completed';
      case DispatchStatus.cancelled:
        return 'Cancelled';
      case DispatchStatus.failed:
        return 'Dispatch Failed';
    }
  }

  /// Returns an informative description for the current stage.
  String get description {
    switch (this) {
      case DispatchStatus.idle:
        return 'System ready. No active emergency.';
      case DispatchStatus.searching:
        return 'Locating closest available ambulances and trauma hospitals.';
      case DispatchStatus.dispatched:
        return 'Emergency alert sent to assigned responder.';
      case DispatchStatus.acknowledged:
        return 'Responder confirmed dispatch and is preparing to deploy.';
      case DispatchStatus.enRoute:
        return 'Ambulance is en route to the incident location.';
      case DispatchStatus.arrived:
        return 'Ambulance has arrived at the scene and is providing first aid.';
      case DispatchStatus.transporting:
        return 'Patient secured in ambulance and heading to designated hospital.';
      case DispatchStatus.delivered:
        return 'Patient admitted to emergency department.';
      case DispatchStatus.completed:
        return 'Emergency response successfully concluded.';
      case DispatchStatus.cancelled:
        return 'Emergency dispatch cancelled.';
      case DispatchStatus.failed:
        return 'Unable to assign responders. Retrying or escalating to manual dispatch.';
    }
  }

  /// Returns a normalized progress value from 0.0 to 1.0.
  double get progressPercentage {
    switch (this) {
      case DispatchStatus.idle:
        return 0.0;
      case DispatchStatus.searching:
        return 0.10;
      case DispatchStatus.dispatched:
        return 0.25;
      case DispatchStatus.acknowledged:
        return 0.40;
      case DispatchStatus.enRoute:
        return 0.60;
      case DispatchStatus.arrived:
        return 0.75;
      case DispatchStatus.transporting:
        return 0.90;
      case DispatchStatus.delivered:
        return 0.98;
      case DispatchStatus.completed:
        return 1.0;
      case DispatchStatus.cancelled:
      case DispatchStatus.failed:
        return 0.0;
    }
  }
}
