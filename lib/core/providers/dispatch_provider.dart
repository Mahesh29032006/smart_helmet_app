import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dispatch_config.dart';
import '../models/dispatch_status.dart';
import '../models/incident.dart';
import '../models/responder.dart';
import '../services/backend_api.dart';
import '../services/dispatch_service.dart';
import '../services/mock_backend_api.dart';
import '../services/web_socket_service.dart';

/// App-wide configuration provider.
final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig();
});

/// Dispatch configuration provider derived from AppConfig.
final dispatchConfigProvider = Provider<DispatchConfig>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return appConfig.dispatchConfig;
});

/// Backend API client provider.
final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  return MockBackendApiClient();
});

/// WebSocket service provider.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final config = ref.watch(dispatchConfigProvider);
  final ws = WebSocketService(config.wsUrl);
  ref.onDispose(() => ws.dispose());
  return ws;
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

/// Stream provider for reactive dispatch status updates in UI.
final dispatchStatusProvider = StreamProvider<DispatchStatus>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  return service.dispatchStatusStream;
});

/// Provider for current assigned primary responder (Ambulance).
final assignedResponderProvider = Provider<Responder?>((ref) {
  final service = ref.watch(dispatchServiceProvider);
  // Also listen to location stream to trigger reactive rebuilds
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
