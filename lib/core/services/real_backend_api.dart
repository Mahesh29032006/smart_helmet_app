import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/incident.dart';
import '../models/location_data.dart';
import '../models/responder.dart';
import '../models/responder_status.dart';
import 'backend_api.dart';

/// Real HTTP backend API client that talks to the Node.js + Express server.
///
/// Implements the existing [BackendApiClient] interface so all existing
/// DispatchService / StateMachineService code works unchanged across Mobile, Desktop, and Web.
class RealBackendApiClient implements BackendApiClient {
  final String baseUrl;
  final String deviceToken;
  final Duration timeout;
  final http.Client _client;

  RealBackendApiClient({
    required this.baseUrl,
    this.deviceToken = '',
    this.timeout = const Duration(seconds: 10),
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (deviceToken.isNotEmpty) 'X-Device-Token': deviceToken,
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.get(uri, headers: _headers).timeout(timeout);
    if (response.statusCode >= 400) {
      throw Exception('GET $path → ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.get(uri, headers: _headers).timeout(timeout);
    if (response.statusCode >= 400) {
      throw Exception('GET $path → ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(uri, headers: _headers, body: jsonEncode(payload))
        .timeout(timeout);
    if (response.statusCode >= 400) {
      throw Exception('POST $path → ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .put(uri, headers: _headers, body: jsonEncode(payload))
        .timeout(timeout);
    if (response.statusCode >= 400) {
      throw Exception('PUT $path → ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }



  // ─── BackendApiClient implementation ─────────────────────────────────────

  @override
  Future<Incident> createIncident(Incident incident) async {
    try {
      final data = await _post('/incidents', incident.toMap());
      return Incident.fromMap(data);
    } catch (_) {
      // Graceful degradation — return the incident as-is
      return incident;
    }
  }

  @override
  Future<Incident> updateIncident(Incident incident) async {
    try {
      final data = await _put('/incidents/${incident.id}', incident.toMap());
      return Incident.fromMap(data);
    } catch (_) {
      return incident;
    }
  }

  @override
  Future<Incident?> getIncident(String incidentId) async {
    try {
      final data = await _get('/incidents/$incidentId');
      return Incident.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Incident>> getAllIncidents() async {
    try {
      final list = await _getList('/incidents');
      return list
          .whereType<Map<String, dynamic>>()
          .map(Incident.fromMap)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Responder>> findNearestResponders(
    LocationData location, {
    double radiusKm = 10.0,
    ResponderType? type,
  }) async {
    try {
      final typeParam = type != null ? '&type=${type.name}' : '';
      final path = '/responders/nearest'
          '?latitude=${location.latitude}'
          '&longitude=${location.longitude}'
          '&radiusKm=$radiusKm'
          '$typeParam';
      final list = await _getList(path);
      return list
          .whereType<Map<String, dynamic>>()
          .map(_responderFromMap)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Incident> assignResponder(String incidentId, String responderId) async {
    try {
      final data = await _put('/incidents/$incidentId', {
        'assignedResponderId': responderId,
        'status': 'dispatched',
      });
      return Incident.fromMap(data);
    } catch (_) {
      throw Exception('assignResponder failed: incidentId=$incidentId');
    }
  }

  @override
  Future<Responder> updateResponderStatus(
      String responderId, ResponderStatus status) async {
    // The minimal backend doesn't have a full responder store.
    // Return a stub that won't break the DispatchService.
    return Responder(
      id: responderId,
      name: responderId,
      type: ResponderType.ambulance,
      status: status,
      location: LocationData(latitude: 0, longitude: 0, timestamp: DateTime.now()),
      phone: '',
    );
  }

  @override
  Future<Responder> updateResponderLocation(
      String responderId, LocationData location) async {
    return Responder(
      id: responderId,
      name: responderId,
      type: ResponderType.ambulance,
      status: ResponderStatus.available,
      location: location,
      phone: '',
    );
  }

  void dispose() {
    _client.close();
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

Responder _responderFromMap(Map<String, dynamic> map) {
  final locMap = map['location'] as Map<String, dynamic>? ?? {};
  return Responder(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    type: ResponderType.values.firstWhere(
      (t) => t.name == (map['type'] as String? ?? 'ambulance'),
      orElse: () => ResponderType.ambulance,
    ),
    status: ResponderStatus.values.firstWhere(
      (s) => s.name == (map['status'] as String? ?? 'available'),
      orElse: () => ResponderStatus.available,
    ),
    location: LocationData(
      latitude: (locMap['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (locMap['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    ),
    phone: map['phone'] as String? ?? '',
    vehicleNumber: map['vehicleNumber'] as String?,
    traumaCapability: map['traumaCapability'] as bool? ?? false,
    rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
    distanceKm: (map['distanceKm'] as num?)?.toDouble(),
  );
}
