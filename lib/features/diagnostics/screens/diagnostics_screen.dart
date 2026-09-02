import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/hardware_telemetry.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';

/// Real Hardware Diagnostics Screen.
/// Shows live connection status, sensor values, GPS, device state.
/// Available in both REAL_HARDWARE and SIMULATION modes.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final mode = config.useRealHardware ? 'REAL HARDWARE' : 'SIMULATION';
    final modeColor = config.useRealHardware ? AppTheme.successColor : AppTheme.warningColor;

    // Real hardware state
    final rtService = ref.watch(realTimeDataServiceProvider);
    final isSocketConnected = ref.watch(isSocketConnectedProvider);
    final deviceStatus = ref.watch(currentDeviceStatusProvider);
    final sensorData = ref.watch(currentSensorDataProvider);
    final location = ref.watch(currentLocationDataProvider);
    final emergencyState = ref.watch(emergencyStateProvider).asData?.value;
    final latestLocation = config.useRealHardware ? ref.watch(realLatestLocationProvider) : null;

    final gpsHasFix = latestLocation != null && config.useRealHardware;
    final satellites = config.useRealHardware
        ? (ref.watch(realLocationStreamProvider).asData?.value != null ? '(real)' : '--')
        : '--';

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Diagnostics'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: modeColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              mode,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: modeColor,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/diagnostics'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Connection Status ────────────────────────────────────────────
          _buildSection('CONNECTION STATUS', [
            _buildRow('Backend', _backendStatus(isSocketConnected, config.useRealHardware)),
            _buildRow('Socket.IO', isSocketConnected ? 'CONNECTED ✓' : 'DISCONNECTED ✗',
                isSocketConnected ? AppTheme.successColor : AppTheme.dangerColor),
            _buildRow('Helmet', _helmetStatus(deviceStatus, config.useRealHardware)),
            _buildRow('Server URL', config.wsUrl, Colors.grey),
            _buildRow('Mode', mode, modeColor),
          ]),

          const SizedBox(height: 16),

          // ─── Telemetry Timestamps ─────────────────────────────────────────
          _buildSection('TELEMETRY TIMESTAMPS', [
            _buildRow('Last Telemetry', _fmtTime(rtService.lastTelemetryAt)),
            _buildRow('Last GPS', _fmtTime(rtService.lastGpsAt)),
            _buildRow('Last Event', rtService.lastEventName ?? '--'),
            _buildRow('Last Incident', rtService.lastIncidentId ?? '--'),
          ]),

          const SizedBox(height: 16),

          // ─── GPS ─────────────────────────────────────────────────────────
          _buildSection('GPS', [
            _buildRow('Fix', gpsHasFix ? 'FIX ✓' : (config.useRealHardware ? 'NO FIX ✗' : 'SIMULATED'),
                gpsHasFix ? AppTheme.successColor : (config.useRealHardware ? AppTheme.dangerColor : AppTheme.warningColor)),
            _buildRow('Satellites', satellites),
            _buildRow('Latitude',
                location.latitude != 0.0
                    ? location.latitude.toStringAsFixed(6)
                    : (config.useRealHardware ? 'Waiting...' : location.latitude.toStringAsFixed(6))),
            _buildRow('Longitude',
                location.longitude != 0.0
                    ? location.longitude.toStringAsFixed(6)
                    : (config.useRealHardware ? 'Waiting...' : location.longitude.toStringAsFixed(6))),
            _buildRow('Altitude', '${location.altitude.toStringAsFixed(1)} m'),
            _buildRow('Speed', '${(location.speed * 3.6).toStringAsFixed(1)} km/h'),
          ]),

          const SizedBox(height: 16),

          // ─── IMU ─────────────────────────────────────────────────────────
          _buildSection('IMU / ACCELEROMETER & GYROSCOPE', [
            _buildRow('AX', '${(sensorData?.accelerometerX ?? 0).toStringAsFixed(3)} m/s²'),
            _buildRow('AY', '${(sensorData?.accelerometerY ?? 0).toStringAsFixed(3)} m/s²'),
            _buildRow('AZ', '${(sensorData?.accelerometerZ ?? 0).toStringAsFixed(3)} m/s²'),
            _buildRow('|A|', '${(sensorData?.totalAcceleration ?? 0).toStringAsFixed(3)} m/s²  '
                '(${(sensorData?.gForce ?? 0).toStringAsFixed(2)} G)',
                _gForceColor(sensorData?.gForce ?? 0)),
            const Divider(height: 12),
            _buildRow('GX', '${(sensorData?.gyroscopeX ?? 0).toStringAsFixed(3)} rad/s'),
            _buildRow('GY', '${(sensorData?.gyroscopeY ?? 0).toStringAsFixed(3)} rad/s'),
            _buildRow('GZ', '${(sensorData?.gyroscopeZ ?? 0).toStringAsFixed(3)} rad/s'),
            _buildRow('|G|', '${(sensorData?.totalAngularVelocity ?? 0).toStringAsFixed(3)} rad/s'),
          ]),

          const SizedBox(height: 16),

          // ─── Emergency ────────────────────────────────────────────────────
          _buildSection('EMERGENCY STATE', [
            _buildRow('State',
                emergencyState?.name.toUpperCase() ?? 'UNKNOWN',
                _emergencyColor(emergencyState?.name ?? 'idle')),
            if (config.useRealHardware) ...[
              _buildRow('Hardware State', rtService.lastEventName ?? 'NORMAL'),
              _buildRow('Last Event', rtService.lastEventName ?? '--'),
            ],
          ]),

          const SizedBox(height: 16),

          // ─── Config ───────────────────────────────────────────────────────
          _buildSection('CONFIGURATION', [
            _buildRow('Device ID', config.deviceId),
            _buildRow('API URL', config.apiBaseUrl),
            _buildRow('Token', config.deviceToken.isEmpty ? '(not set)' : '****',
                config.deviceToken.isEmpty ? AppTheme.dangerColor : AppTheme.successColor),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _backendStatus(bool socketConnected, bool useRealHardware) {
    if (!useRealHardware) return 'N/A (SIMULATION)';
    return socketConnected ? 'ONLINE ✓' : 'OFFLINE ✗';
  }

  String _helmetStatus(DeviceConnectionStatus status, bool useRealHardware) {
    if (!useRealHardware) return 'SIMULATED';
    switch (status) {
      case DeviceConnectionStatus.online: return 'ONLINE ✓';
      case DeviceConnectionStatus.stale: return 'STALE ⚠';
      case DeviceConnectionStatus.offline: return 'OFFLINE ✗';
    }
  }

  Color _gForceColor(double g) {
    if (g < 1.5) return AppTheme.successColor;
    if (g < 3.0) return AppTheme.warningColor;
    return AppTheme.dangerColor;
  }

  Color _emergencyColor(String state) {
    switch (state.toLowerCase()) {
      case 'monitoring': case 'idle': return AppTheme.successColor;
      case 'countdown': case 'crashdetected': return AppTheme.warningColor;
      case 'confirmed': case 'dispatched': return AppTheme.dangerColor;
      case 'cancelled': case 'resolved': return AppTheme.infoColor;
      default: return Colors.grey;
    }
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '--';
    final ago = DateTime.now().difference(dt);
    if (ago.inSeconds < 60) return '${ago.inSeconds}s ago';
    if (ago.inMinutes < 60) return '${ago.inMinutes}m ago';
    return DateFormat('HH:mm:ss').format(dt.toLocal());
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
