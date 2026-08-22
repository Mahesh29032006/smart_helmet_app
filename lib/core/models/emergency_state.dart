/// System-wide emergency state machine stages.
enum EmergencyState {
  idle,
  monitoring,
  crashDetected,
  countdown,
  confirmed,
  dispatched,
  cancelled,
  resolved;

  bool get isActiveEmergency =>
      this == EmergencyState.crashDetected ||
      this == EmergencyState.countdown ||
      this == EmergencyState.confirmed ||
      this == EmergencyState.dispatched;
}
