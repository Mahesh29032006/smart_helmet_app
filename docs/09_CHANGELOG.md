# Project Changelog

## 2026-08-23

### Phase 5: Incident Model & Backend API Integration
- Implemented `IncidentStatus` enum & `IncidentStatusExtension` (`lib/core/models/incident_status.dart`) supporting 8 lifecycle stages (`pending`, `confirmed`, `dispatched`, `enRoute`, `arrived`, `closed`, `cancelled`, `failed`), string parsing, and status classification helpers.
- Implemented `Incident` unified model (`lib/core/models/incident.dart`) with unique ID, rider/device identifiers, status, automated severity classification (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`), confidence score, captured `LocationData`, peak impact magnitude, orientation tilt change, freshness metadata, lifecycle timestamps, notes, raw sensor evidence snapshots, and resilient JSON serialization.
- Implemented `ResponderType` enum, `Responder` model (`lib/core/models/responder.dart`), and `DispatchResponse` model (`lib/core/models/dispatch_response.dart`) for ambulance and hospital dispatch assignment.
- Implemented `AppConfig` model (`lib/core/models/app_config.dart`) providing base API URL, rider/device identifiers, and mock/live backend toggle.
- Implemented `IncidentService` (`lib/core/services/incident_service.dart`) providing in-memory local incident history management, stream emitters (`incidentsStream`, `incidentUpdates`), and `SharedPreferences` persistence across app restarts.
- Implemented `BackendApiClient` (`lib/core/services/backend_api_client.dart`) utilizing `Dio` for REST API endpoints (`/incidents`, `/incidents/:id`, `/incidents/:id/cancel`, `/incidents/:id/dispatch`, `/responders/nearby`).
- Implemented `MockBackendApiClient` (`lib/core/services/mock_backend_api_client.dart`) with in-memory store, realistic Haversine distance calculations, simulated latency, emergency responder assignments, and granular error simulation toggles.
- Integrated `StateMachineService` (`lib/core/services/state_machine_service.dart`) with `IncidentService` and `BackendApiClient` to automatically capture location, create incident records, and dispatch to backend upon crash confirmation.
- Configured Riverpod providers (`lib/core/providers/incident_provider.dart` and updated `state_machine_provider.dart`) exposing `appConfigProvider`, `incidentServiceProvider`, `backendApiProvider`, `incidentsListProvider`, `activeIncidentsProvider`, `lastCreatedIncidentProvider`, and wired `stateMachineProvider`.
- Updated core barrel export (`lib/core/core.dart`).
- Added comprehensive unit and integration test suites (`test/core/models/incident_test.dart`, `test/core/models/responder_test.dart`, `test/core/services/incident_service_test.dart`, `test/core/services/mock_backend_api_client_test.dart`, `test/core/services/incident_integration_test.dart`) covering all model serialization, service operations, error handling, backend integration, and Riverpod DI (114 total project tests passing, `flutter analyze` 0 issues).

### Phase 4: Location Provider (Simulated GPS & Geolocation)
- Implemented `LocationData` model (`lib/core/models/location_data.dart`) with latitude, longitude, accuracy, timestamp, freshness calculation (`isFreshAt`, `getAge`), origin source tracking (`"simulated"`, `"gps"`, `"cached"`), altitude, speed, heading, and JSON serialization.
- Implemented `LocationConfig` model (`lib/core/models/location_config.dart`) providing customizable update intervals (default 1s), fresh thresholds (default 30s), default Bhubaneswar coordinates (20.2961, 85.8245), movement speed, accuracy, and event logging callbacks.
- Defined `LocationSimulationScenario` enum (`lib/core/enums/location_simulation_scenario.dart`) with `fixed`, `moving`, `gpsUnavailable`, `staleGps`, and `gpsRecovering` scenarios.
- Implemented `LocationService` interface contract (`lib/core/interfaces/location_service.dart`) with `locationStream`, `currentLocation`, `isRunning`, `start()`, `stop()`, `getFreshLocation()`, and `getLastKnownLocation()`.
- Implemented `SimulatedLocationService` (`lib/core/services/simulated_location_service.dart`) supporting fixed position, incremental realistic motion simulation, GPS signal loss, stale fix emission, accuracy degradation, custom fix emission, and cached fallback.
- Implemented `RealLocationService` (`lib/core/services/real_location_service.dart`) stub ready for `geolocator` with graceful fallback to simulated GPS.
- Configured Riverpod providers (`lib/core/providers/location_provider.dart`) exposing `locationConfigProvider`, `locationServiceProvider`, `currentLocationProvider`, `freshLocationProvider`, and `lastKnownLocationProvider`.
- Integrated `LocationService` with `StateMachineService` (`lib/core/services/state_machine_service.dart`) to capture fresh GPS fixes when a crash is confirmed or seamlessly fallback to cached location if GPS is lost.
- Updated core barrel export (`lib/core/core.dart`).
- Added comprehensive unit and integration test suites (`test/core/models/location_data_test.dart` and `test/core/services/location_service_test.dart`) covering all simulation scenarios, Riverpod DI, and StateMachine confirmation integration (81 total tests passing, 0 warnings).

### Phase 3: State Machine & Countdown Timer
- Implemented `CrashState` enum & `CrashStateExtension` (`lib/core/models/crash_state.dart`) supporting 10 lifecycle states (`normal`, `suspected`, `countdown`, `confirmed`, `cancelled`, `dispatched`, `enRoute`, `arrived`, `closed`, `failed`) and UI status helper properties.
- Implemented `StateMachineConfig` (`lib/core/models/state_machine_config.dart`) for configurable countdown duration (default 10s), reset delay, high-confidence skip threshold (0.9), and logging callbacks.
- Implemented `StateMachineService` (`lib/core/services/state_machine_service.dart`) managing the crash lifecycle, listening to `CrashDetectionService`, automatically starting cancellation countdowns, handling high-confidence direct confirmations, and routing emergency response stages.
- Configured Riverpod providers (`lib/core/providers/state_machine_provider.dart`) exposing `stateMachineProvider`, `stateStreamProvider`, and `countdownStreamProvider`.
- Updated barrel exports (`lib/core/core.dart`).
- Added comprehensive unit test suite (`test/core/services/state_machine_service_test.dart`) covering all state transitions, countdown timer ticks, cancellation resets, high-confidence skips, emergency workflow stages, failure handling, and Riverpod DI (53 total project tests passing with 0 warnings).

### Phase 2: Crash Detection Engine
- Implemented `DetectionEvent` enum & `CrashDetectionResult` model (`lib/core/models/detection_event.dart`) providing multi-signal explainability, normalized scoring, and JSON serialization.
- Implemented `CrashDetectionService` (`lib/core/services/crash_detection_service.dart`) utilizing multi-signal sensor fusion (impact magnitude, orientation change, post-impact inactivity duration) with configurable thresholds and explainable diagnostics.
- Configured Riverpod providers (`lib/core/providers/crash_detection_provider.dart`) for dependency injection of `CrashDetectionService`, `SensorService`, and reactive state streams.
- Updated core barrel export (`lib/core/core.dart`).
- Added comprehensive unit test suite (`test/core/services/crash_detection_service_test.dart`) covering all simulation scenarios (Normal riding, Pothole false positive avoidance, Genuine crash verification, Helmet drop non-confirmation, Sudden braking, Cancellation, and Riverpod DI) with 100% pass rate.

### Phase 1: SensorData Model & SensorSimulator Service
- Implemented `SensorData` model (`lib/core/models/sensor_data.dart`) with 3-axis accelerometer/gyroscope, orientation, movement, battery level, optional GPS coordinates, and JSON serialization.
- Implemented `SensorService` interface (`lib/core/interfaces/sensor_service_interface.dart`) for hardware/simulation abstraction.
- Implemented `SensorSimulator` service (`lib/core/services/sensor_simulator.dart`) supporting realistic time-series data for all scenarios (Normal Riding, Pothole, Genuine Crash, Helmet Drop, Sudden Braking, Minor Impact, Sensor Noise, Inactivity).
- Defined `SimulationScenario` enum (`lib/core/enums/simulation_scenario.dart`).
- Created barrel export (`lib/core/core.dart`).
- Added comprehensive unit test suites (`test/core/models/sensor_data_test.dart` and `test/core/services/sensor_simulator_test.dart`) with 100% pass rate.

### Initialized
- Created repository structure
- Created documentation system
- Established sensor abstraction strategy
- Established simulated-sensor development mode
- Established change-management process
