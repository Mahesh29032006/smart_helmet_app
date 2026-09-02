import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../models/emergency_state.dart';
import '../models/hardware_telemetry.dart';
import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/sensor_data.dart';

/// Real-time data service for the Smart Helmet backend connection.
///
/// Uses socket_io_client to connect to the Node.js + Socket.IO backend.
/// Receives telemetry broadcast events and translates them to typed streams
/// consumed by Riverpod providers.
///
/// This service is ONLY active in REAL_HARDWARE mode.
/// The simulation path (SensorSimulator, LocationProvider) is unaffected.
class RealTimeDataService {
  final String serverUrl;
  final String deviceId;

  sio.Socket? _socket;

  bool _connected = false;
  DateTime? _lastTelemetryAt;
  DateTime? _lastGpsAt;
  String? _lastEventName;
  String? _lastIncidentId;
  DeviceConnectionStatus _deviceStatus = DeviceConnectionStatus.offline;

  EmergencyState _currentHardwareState = EmergencyState.monitoring;
  LocationData? _lastLocation;
  SensorData? _lastSensor;

  final _sensorController = StreamController<SensorData>.broadcast();
  final _locationController = StreamController<LocationData>.broadcast();
  final _hardwareStateController = StreamController<EmergencyState>.broadcast();
  final _incidentController = StreamController<Incident>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _deviceStatusController = StreamController<DeviceConnectionStatus>.broadcast();

  // ─── Public Streams ─────────────────────────────────────────────────────

  /// Real IMU data from the helmet.
  Stream<SensorData> get sensorStream => _sensorController.stream;

  /// Real GPS data from the helmet (only emitted when fix=true).
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Hardware emergency state (maps to existing EmergencyState enum).
  Stream<EmergencyState> get hardwareStateStream => _hardwareStateController.stream;

  /// Incidents created by the backend on EMERGENCY_CONFIRMED.
  Stream<Incident> get incidentStream => _incidentController.stream;

  /// Socket.IO connection status (true = connected).
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Device (helmet) online/stale/offline status.
  Stream<DeviceConnectionStatus> get deviceStatusStream => _deviceStatusController.stream;

  // ─── Sync Accessors ──────────────────────────────────────────────────────

  bool get isConnected => _connected;
  DeviceConnectionStatus get deviceStatus => _deviceStatus;
  EmergencyState get currentHardwareState => _currentHardwareState;
  SensorData? get lastSensor => _lastSensor;
  LocationData? get lastLocation => _lastLocation;
  DateTime? get lastTelemetryAt => _lastTelemetryAt;
  DateTime? get lastGpsAt => _lastGpsAt;
  String? get lastEventName => _lastEventName;
  String? get lastIncidentId => _lastIncidentId;

  RealTimeDataService({
    required this.serverUrl,
    this.deviceId = 'helmet-01',
  });

  // ─── Connection ──────────────────────────────────────────────────────────

  void connect() {
    if (_socket != null) return; // Already created

    _socket = sio.io(
      serverUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      _connectionController.add(true);
      if (kDebugMode) print('[RealTimeDataService] Connected to $serverUrl');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      _connectionController.add(false);
      if (kDebugMode) print('[RealTimeDataService] Disconnected');
    });

    _socket!.onConnectError((err) {
      _connected = false;
      _connectionController.add(false);
      if (kDebugMode) print('[RealTimeDataService] Connection error: $err');
    });

    _socket!.onError((err) {
      if (kDebugMode) print('[RealTimeDataService] Error: $err');
    });

    // ─── Event Listeners ──────────────────────────────────────────────────

    _socket!.on('sensor.update', _onSensorUpdate);
    _socket!.on('location.update', _onLocationUpdate);
    _socket!.on('emergency.state', _onEmergencyState);
    _socket!.on('incident.created', _onIncidentCreated);
    _socket!.on('incident.updated', _onIncidentUpdated);
    _socket!.on('device.update', _onDeviceUpdate);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  // ─── Event Handlers ──────────────────────────────────────────────────────

  void _onSensorUpdate(dynamic data) {
    if (data is! Map) return;
    try {
      final map = Map<String, dynamic>.from(data);
      // Only process events for our device (or any device if deviceId not present)
      final did = map['deviceId'] as String?;
      if (did != null && did != deviceId) return;

      final sensor = SensorDataHardware.fromHardwareSensorEvent(map);
      _lastSensor = sensor;
      _lastTelemetryAt = DateTime.now();
      _sensorController.add(sensor);
    } catch (e) {
      if (kDebugMode) print('[RealTimeDataService] sensor.update parse error: $e');
    }
  }

  void _onLocationUpdate(dynamic data) {
    if (data is! Map) return;
    try {
      final map = Map<String, dynamic>.from(data);
      final did = map['deviceId'] as String?;
      if (did != null && did != deviceId) return;

      final location = LocationDataHardware.fromHardwareLocationEvent(map);
      if (location != null) {
        _lastLocation = location;
        _lastGpsAt = DateTime.now();
        _locationController.add(location);
      }
    } catch (e) {
      if (kDebugMode) print('[RealTimeDataService] location.update parse error: $e');
    }
  }

  void _onEmergencyState(dynamic data) {
    if (data is! Map) return;
    try {
      final map = Map<String, dynamic>.from(data);
      final did = map['deviceId'] as String?;
      if (did != null && did != deviceId) return;

      final stateStr = map['state'] as String? ?? HardwareStates.normal;
      _lastEventName = map['event'] as String? ?? stateStr;
      final newState = _mapHardwareState(stateStr);

      if (newState != _currentHardwareState) {
        _currentHardwareState = newState;
        _hardwareStateController.add(newState);
        if (kDebugMode) print('[RealTimeDataService] Hardware state: $stateStr → $newState');
      }
    } catch (e) {
      if (kDebugMode) print('[RealTimeDataService] emergency.state parse error: $e');
    }
  }

  void _onIncidentCreated(dynamic data) {
    if (data is! Map) return;
    try {
      final map = Map<String, dynamic>.from(data);
      final incident = _parseIncident(map);
      if (incident != null) {
        _lastIncidentId = incident.id;
        _incidentController.add(incident);
        if (kDebugMode) print('[RealTimeDataService] Incident created: ${incident.id}');
      }
    } catch (e) {
      if (kDebugMode) print('[RealTimeDataService] incident.created parse error: $e');
    }
  }

  void _onIncidentUpdated(dynamic data) {
    if (data is! Map) return;
    try {
      final map = Map<String, dynamic>.from(data);
      final incident = _parseIncident(map);
      if (incident != null) {
        _lastIncidentId = incident.id;
        _incidentController.add(incident);
      }
    } catch (e) {
      if (kDebugMode) print('[RealTimeDataService] incident.updated parse error: $e');
    }
  }

  void _onDeviceUpdate(dynamic data) {
    if (data is! Map) return;
    try {
      final map = Map<String, dynamic>.from(data);
      final did = map['deviceId'] as String?;
      if (did != null && did != deviceId) return;

      final statusStr = map['status'] as String? ?? 'offline';
      final newStatus = _mapDeviceStatus(statusStr);
      if (newStatus != _deviceStatus) {
        _deviceStatus = newStatus;
        _deviceStatusController.add(newStatus);
      }
    } catch (e) {
      if (kDebugMode) print('[RealTimeDataService] device.update parse error: $e');
    }
  }

  // ─── Mapping helpers ─────────────────────────────────────────────────────

  /// Maps hardware state string → existing EmergencyState enum.
  static EmergencyState _mapHardwareState(String stateStr) {
    switch (stateStr) {
      case HardwareStates.crashPending:
        return EmergencyState.countdown;
      case HardwareStates.emergencyConfirmed:
      case HardwareStates.manualEmergency:
        return EmergencyState.confirmed;
      case HardwareStates.cancelled:
        return EmergencyState.cancelled;
      case HardwareStates.normal:
      default:
        return EmergencyState.monitoring;
    }
  }

  static DeviceConnectionStatus _mapDeviceStatus(String s) {
    switch (s) {
      case 'online': return DeviceConnectionStatus.online;
      case 'stale': return DeviceConnectionStatus.stale;
      default: return DeviceConnectionStatus.offline;
    }
  }

  /// Parses an incident from the backend JSON.
  /// Backend may not have all Flutter fields — we use safe fallbacks.
  static Incident? _parseIncident(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    if (id == null) return null;

    LocationData location;
    final locMap = map['location'];
    if (locMap is Map<String, dynamic>) {
      location = LocationData.fromMap(locMap);
    } else {
      // Backend had no GPS fix — use dummy coords but mark with null address
      location = LocationData(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        address: 'GPS fix unavailable',
      );
    }

    final severityStr = map['severity'] as String? ?? 'high';
    final statusStr = map['status'] as String? ?? 'open';
    final metadata = map['metadata'];

    return Incident(
      id: id,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      location: location,
      severity: IncidentSeverity.values.firstWhere(
        (s) => s.name == severityStr,
        orElse: () => IncidentSeverity.high,
      ),
      status: IncidentStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => IncidentStatus.open,
      ),
      crashConfidence: (map['crashConfidence'] as num?)?.toDouble() ?? 0.98,
      metadata: metadata is Map<String, dynamic> ? metadata : null,
    );
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  void dispose() {
    disconnect();
    _sensorController.close();
    _locationController.close();
    _hardwareStateController.close();
    _incidentController.close();
    _connectionController.close();
    _deviceStatusController.close();
  }
}
