import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/dispatch_config.dart';
import '../models/dispatch_status.dart';
import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/responder_status.dart';
import '../models/web_socket_event.dart';
import 'backend_api.dart';
import 'dispatch_simulation.dart';
import 'mock_backend_api.dart';
import 'web_socket_service.dart';

/// Core orchestrator for the Emergency Response Lifecycle.
class DispatchService {
  final DispatchConfig config;
  final BackendApiClient backendClient;
  final WebSocketService? webSocketService;

  DispatchStatus _currentStatus = DispatchStatus.idle;
  Responder? _assignedResponder;
  Responder? _assignedHospital;
  Incident? _currentIncident;

  final _statusController = StreamController<DispatchStatus>.broadcast(sync: true);
  final _responderLocationController = StreamController<Responder>.broadcast(sync: true);
  final _incidentUpdatesController = StreamController<String>.broadcast(sync: true);

  DispatchSimulation? _simulation;
  StreamSubscription<WebSocketEvent>? _wsSubscription;

  // Rejected responder IDs for the current incident to avoid infinite re-assignment loop
  final Set<String> _rejectedResponderIds = {};

  DispatchService({
    DispatchConfig? config,
    BackendApiClient? backendClient,
    this.webSocketService,
  })  : config = config ?? const DispatchConfig(),
        backendClient = backendClient ?? MockBackendApiClient() {
    _initWebSocketListener();
  }

  // --- Streams ---
  Stream<DispatchStatus> get dispatchStatusStream => _statusController.stream;
  Stream<Responder> get responderLocationStream =>
      _responderLocationController.stream;
  Stream<String> get incidentUpdates => _incidentUpdatesController.stream;

  // --- State Getters ---
  DispatchStatus get currentStatus => _currentStatus;
  Responder? get assignedResponder => _assignedResponder;
  Responder? get assignedHospital => _assignedHospital;
  Incident? get currentIncident => _currentIncident;

  // --- Lifecycle Actions ---

  /// Starts the dispatch process for a confirmed emergency incident.
  Future<void> startDispatch(
    Incident incident, {
    bool resetRejections = true,
  }) async {
    if (resetRejections || _currentIncident?.id != incident.id) {
      _rejectedResponderIds.clear();
    }
    _currentIncident = incident;
    _updateStatus(DispatchStatus.searching);

    final loc = incident.location;
    _log(
        '[Dispatch] Searching for responders near ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}');

    // Subscribe to real-time incident room on WebSocket if active
    if (webSocketService != null && webSocketService!.isConnected) {
      webSocketService!.subscribeToIncident(incident.id);
    }

    try {
      // Step 1: Query nearest available responders
      final ambulances = await backendClient.findNearestResponders(
        loc,
        radiusKm: config.maxResponderDistanceKm,
        type: ResponderType.ambulance,
      );

      // Filter out rejected responders and unavailable ones
      final availableAmbulances = ambulances
          .where((a) =>
              !_rejectedResponderIds.contains(a.id) &&
              a.status == ResponderStatus.available)
          .toList();

      if (availableAmbulances.isEmpty) {
        _assignedResponder = null;
        _log(
            '[Dispatch] No available ambulances found within ${config.maxResponderDistanceKm}km');
        _updateStatus(DispatchStatus.failed);
        return;
      }

      final chosenAmbulance = availableAmbulances.first;
      _assignedResponder = chosenAmbulance;

      // Step 2: Query nearest trauma center hospital
      final hospitals = await backendClient.findNearestResponders(
        loc,
        radiusKm: 25.0,
        type: ResponderType.hospital,
      );

      final traumaHospitals =
          hospitals.where((h) => h.traumaCapability).toList();
      _assignedHospital =
          traumaHospitals.isNotEmpty ? traumaHospitals.first : hospitals.firstOrNull;

      final distanceKm = chosenAmbulance.distanceKm ??
          calculateDistance(chosenAmbulance.location, loc);
      final etaMin = chosenAmbulance.etaMinutes ??
          calculateETA(
            chosenAmbulance.location,
            loc,
            avgSpeedKmph: config.ambulanceAvgSpeedKmph,
          );

      _log(
          '[Dispatch] Found: ${chosenAmbulance.name} (${distanceKm.toStringAsFixed(1)}km away)');
      _log('[Dispatch] Dispatch sent to ${chosenAmbulance.name}');

      _updateStatus(DispatchStatus.dispatched);
      _currentIncident = _currentIncident?.copyWith(
        assignedResponderId: chosenAmbulance.id,
        assignedHospitalId: _assignedHospital?.id,
        distanceKm: distanceKm,
        etaMinutes: etaMin,
        status: IncidentStatus.dispatched,
      );

      if (config.useSimulation && config.autoProgressSimulation) {
        _startSimulationFlow();
      }
    } catch (e) {
      _log('[Dispatch] Error starting dispatch: $e');
      _updateStatus(DispatchStatus.failed);
    }
  }

  /// Responder accepts the assigned dispatch.
  Future<void> acceptDispatch(String responderId) async {
    if (_assignedResponder?.id != responderId) return;

    final responder = _assignedResponder!;
    final etaMin = _currentIncident?.etaMinutes ??
        calculateETA(
          responder.location,
          _currentIncident!.location,
          avgSpeedKmph: config.ambulanceAvgSpeedKmph,
        );

    _log('[Dispatch] ${responder.name} accepted (ETA: ${etaMin.toStringAsFixed(0)} min)');
    _updateStatus(DispatchStatus.acknowledged);

    await updateResponderStatus(responderId, ResponderStatus.dispatched);

    // Notify backend WebSocket
    webSocketService?.send(WebSocketEvent.clientAccept, {
      'incidentId': _currentIncident?.id,
      'responderId': responderId,
    });
  }

  /// Responder rejects or declines the dispatch.
  Future<void> rejectDispatch(String responderId) async {
    _log('[Dispatch] Responder $responderId rejected dispatch. Re-routing...');
    _rejectedResponderIds.add(responderId);

    webSocketService?.send(WebSocketEvent.clientReject, {
      'incidentId': _currentIncident?.id,
      'responderId': responderId,
    });

    if (_currentIncident != null) {
      // Re-search for next candidate without resetting rejected set
      await startDispatch(_currentIncident!, resetRejections: false);
    }
  }

  /// Updates status of responder (e.g. enRoute, arrived, transporting).
  Future<void> updateResponderStatus(
    String responderId,
    ResponderStatus status,
  ) async {
    if (_assignedResponder != null && _assignedResponder!.id == responderId) {
      _assignedResponder = _assignedResponder!.copyWith(status: status);
      _responderLocationController.add(_assignedResponder!);

      // Sync dispatch status with responder progression
      switch (status) {
        case ResponderStatus.enRoute:
          _log('[Dispatch] ${_assignedResponder!.name} en route');
          _updateStatus(DispatchStatus.enRoute);
          break;
        case ResponderStatus.arrived:
          _log('[Dispatch] ${_assignedResponder!.name} arrived at scene');
          _updateStatus(DispatchStatus.arrived);
          break;
        case ResponderStatus.transporting:
          final hosp = _assignedHospital?.name ?? 'City Trauma Centre';
          _log('[Dispatch] Patient transported to $hosp');
          _updateStatus(DispatchStatus.transporting);
          break;
        case ResponderStatus.available:
          if (_currentStatus == DispatchStatus.transporting) {
            _updateStatus(DispatchStatus.delivered);
          }
          break;
        default:
          break;
      }

      await backendClient.updateResponderStatus(responderId, status);
    }
  }

  /// Updates responder's real-time coordinate position.
  Future<void> updateResponderLocation(
    String responderId,
    LocationData location,
  ) async {
    if (_assignedResponder != null && _assignedResponder!.id == responderId) {
      final dest = _currentStatus == DispatchStatus.transporting
          ? (_assignedHospital?.location ?? location)
          : (_currentIncident?.location ?? location);

      final dist = calculateDistance(location, dest);
      final eta = calculateETA(
        location,
        dest,
        avgSpeedKmph: config.ambulanceAvgSpeedKmph,
      );

      _assignedResponder = _assignedResponder!.copyWith(
        location: location,
        distanceKm: dist,
        etaMinutes: eta,
      );
      _responderLocationController.add(_assignedResponder!);

      webSocketService?.send(WebSocketEvent.clientUpdateLocation, {
        'responderId': responderId,
        'location': location.toMap(),
        'incidentId': _currentIncident?.id,
      });

      await backendClient.updateResponderLocation(responderId, location);
    }
  }

  /// Completes and resolves the dispatch and incident.
  Future<void> completeDispatch(String incidentId) async {
    _simulation?.cancel();
    _log('[Dispatch] Incident resolved');
    _updateStatus(DispatchStatus.completed);

    if (_assignedResponder != null) {
      await updateResponderStatus(
        _assignedResponder!.id,
        ResponderStatus.available,
      );
    }

    if (_currentIncident != null) {
      _currentIncident = _currentIncident!.copyWith(
        status: IncidentStatus.resolved,
      );
      await backendClient.updateIncident(_currentIncident!);
    }

    if (webSocketService != null && webSocketService!.isConnected) {
      webSocketService!.unsubscribeFromIncident(incidentId);
    }
  }

  /// Cancels an in-progress dispatch.
  Future<void> cancelDispatch(String incidentId) async {
    _simulation?.cancel();
    _log('[Dispatch] Emergency dispatch cancelled');
    _updateStatus(DispatchStatus.cancelled);

    if (_assignedResponder != null) {
      await updateResponderStatus(
        _assignedResponder!.id,
        ResponderStatus.available,
      );
    }

    if (_currentIncident != null) {
      _currentIncident = _currentIncident!.copyWith(
        status: IncidentStatus.cancelled,
      );
      await backendClient.updateIncident(_currentIncident!);
    }

    if (webSocketService != null && webSocketService!.isConnected) {
      webSocketService!.unsubscribeFromIncident(incidentId);
    }
  }

  // --- Internal Helpers ---

  void _startSimulationFlow() {
    if (_currentIncident == null || _assignedResponder == null) return;

    _simulation?.cancel();
    _simulation = DispatchSimulation(
      config: config.simulationConfig,
      onStatusChanged: (status) {
        _updateStatus(status);
      },
      onLocationUpdated: (responder) {
        _assignedResponder = responder;
        _responderLocationController.add(responder);
      },
      onLog: (msg) {
        _log(msg);
      },
    );

    _simulation!.runSimulation(
      incident: _currentIncident!,
      responder: _assignedResponder!,
      hospital: _assignedHospital,
    );
  }

  void _initWebSocketListener() {
    if (webSocketService == null) return;
    _wsSubscription = webSocketService!.eventStream.listen((event) {
      _handleWebSocketEvent(event);
    });
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.event) {
      case WebSocketEvent.incidentDispatched:
        _updateStatus(DispatchStatus.dispatched);
        break;
      case WebSocketEvent.responderAccepted:
        _updateStatus(DispatchStatus.acknowledged);
        break;
      case WebSocketEvent.responderLocationUpdated:
        if (event.data is Map<String, dynamic> &&
            event.data['location'] != null) {
          final loc = LocationData.fromMap(
              event.data['location'] as Map<String, dynamic>);
          final respId = event.data['responderId'] as String? ??
              _assignedResponder?.id ??
              '';
          updateResponderLocation(respId, loc);
        }
        break;
      case WebSocketEvent.responderArrived:
        _updateStatus(DispatchStatus.arrived);
        break;
      case WebSocketEvent.incidentClosed:
        _updateStatus(DispatchStatus.completed);
        break;
      case WebSocketEvent.incidentCancelled:
        _updateStatus(DispatchStatus.cancelled);
        break;
      default:
        break;
    }
  }

  void _updateStatus(DispatchStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _log(String message) {
    _incidentUpdatesController.add(message);
    if (kDebugMode) {
      print(message);
    }
  }

  void dispose() {
    _simulation?.cancel();
    _wsSubscription?.cancel();
    _statusController.close();
    _responderLocationController.close();
    _incidentUpdatesController.close();
  }
}
