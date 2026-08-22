# RescueLink Emergency Response System - Architecture Document

## 1. System Architecture Overview

The system provides an end-to-end autonomous crash detection, emergency confirmation, and multi-agency response workflow.

```mermaid
graph TD
    A[Sensors / Telemetry] --> B[SensorSimulator / IMU]
    B --> C[CrashDetectionService]
    C -->|Crash Event| D[StateMachineService]
    D -->|User Cancel| E[Cancelled State]
    D -->|Countdown Expire / Manual Confirm| F[Confirmed Emergency]
    F --> G[DispatchService]
    G <--> H[MockBackendApiClient / REST API]
    G <--> I[WebSocketService / Socket.IO]
    G <--> J[DispatchSimulation Engine]
    G --> K[Riverpod State Providers]
    K --> L[Flutter UI Dashboards]
```

## 2. Component Responsibilities

### 2.1 State Machine Lifecycle
```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Monitoring: Start Monitoring
    Monitoring --> CrashDetected: G-Force / Gyro Threshold Exceeded
    CrashDetected --> Countdown: Start 15s Countdown
    Countdown --> Cancelled: User Clicks "I'm OK"
    Countdown --> Confirmed: Countdown Reaches 0 / User Clicks "Call Help"
    Confirmed --> Dispatched: Auto Trigger Dispatch
    Dispatched --> Resolved: Incident Closed
    Cancelled --> Idle: Reset
    Resolved --> Idle: Reset
```

### 2.2 Dispatch Lifecycle (`DispatchStatus`)
1. **`idle`**: No active emergency.
2. **`searching`**: System queries nearest available ambulances within 10km and trauma hospitals.
3. **`dispatched`**: Alert dispatched to closest responder.
4. **`acknowledged`**: Responder accepts the assignment.
5. **`enRoute`**: Responder en route to scene with real-time GPS telemetry.
6. **`arrived`**: Responder arrives on scene for triage.
7. **`transporting`**: Patient in ambulance moving towards designated trauma center.
8. **`delivered`**: Patient delivered safely to emergency department.
9. **`completed`**: Incident resolved.
10. **`cancelled`**: Dispatch aborted.
11. **`failed`**: No responders available within range or system failure.

## 3. Real-time Communication
- Duplex WebSocket connection using Socket.IO events.
- Rooms/channels segmented by `incidentId`.
- Bidirectional updates for location, status transitions, and cancellations.
