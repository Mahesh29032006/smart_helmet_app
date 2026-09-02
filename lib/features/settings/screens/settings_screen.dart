import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';

/// Screen 8: Settings and Hardware / Algorithm Calibration Screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final configNotifier = ref.read(appConfigNotifierProvider.notifier);
    final uiLogs = ref.watch(uiLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings & Calibration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Defaults',
            onPressed: () {
              configNotifier.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to system defaults')),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Section 0: Appearance & Theme
          _buildSectionHeader('APPEARANCE & THEME'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Application Theme Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.settings_brightness, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode, size: 16),
                    ),
                  ],
                  selected: {config.themeMode},
                  onSelectionChanged: (newSelection) {
                    configNotifier.setThemeMode(newSelection.first);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Section 1: Presentation & Demo Mode
          _buildSectionHeader('PRESENTATION & DEMO MODE'),
          SwitchListTile(
            title: const Text(
              'Demo Mode (Auto-Crash)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Automatically triggers a crash event after delay for demo'),
            value: config.demoMode,
            activeTrackColor: AppTheme.dangerLight,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.dangerColor;
              }
              return null;
            }),
            onChanged: (val) {
              configNotifier.setDemoMode(val);
            },
          ),
          if (config.demoMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Demo Delay: '),
                  Text(
                    '${config.demoDelaySeconds} seconds',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
                  ),
                ],
              ),
            ),
            Slider(
              value: config.demoDelaySeconds.toDouble(),
              min: 2,
              max: 20,
              divisions: 18,
              label: '${config.demoDelaySeconds}s',
              activeColor: AppTheme.dangerColor,
              onChanged: (val) {
                configNotifier.setDemoDelay(val.toInt());
              },
            ),
          ],
          SwitchListTile(
            title: const Text('Show Debug Sensor Telemetry'),
            subtitle: const Text('Displays live 3-axis accelerometer and gyro values in UI'),
            value: config.showDebugInfo,
            activeTrackColor: AppTheme.primaryLight,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primaryColor;
              }
              return null;
            }),
            onChanged: (val) {
              configNotifier.setShowDebugInfo(val);
            },
          ),
          SwitchListTile(
            title: const Text('Auditory Emergency Chimes'),
            subtitle: const Text('Plays alarm sounds during detected crash count-down and alerts'),
            value: config.enableSound,
            activeTrackColor: AppTheme.warningLight,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.warningColor;
              }
              return null;
            }),
            onChanged: (val) {
              configNotifier.setEnableSound(val);
            },
          ),
          SwitchListTile(
            title: const Text('Haptic Vibration Alerts'),
            subtitle: const Text('Vibrates device during active emergency confirmation'),
            value: config.enableHaptics,
            activeTrackColor: AppTheme.primaryLight,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primaryColor;
              }
              return null;
            }),
            onChanged: (val) {
              configNotifier.setEnableHaptics(val);
            },
          ),
          const Divider(height: 24),

          // Section 2: Crash Detection Algorithm Calibration
          _buildSectionHeader('CRASH DETECTION ALGORITHM CALIBRATION'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('G-Force Impact Threshold:'),
                    Text(
                      '${config.gForceThreshold.toStringAsFixed(1)} G',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                Slider(
                  value: config.gForceThreshold,
                  min: 1.5,
                  max: 6.0,
                  divisions: 45,
                  label: '${config.gForceThreshold.toStringAsFixed(1)} G',
                  onChanged: (val) {
                    configNotifier.setGForceThreshold(val);
                  },
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Angular Velocity Threshold:'),
                    Text(
                      '${config.angularVelocityThreshold.toStringAsFixed(1)} rad/s',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                Slider(
                  value: config.angularVelocityThreshold,
                  min: 1.0,
                  max: 5.0,
                  divisions: 40,
                  label: '${config.angularVelocityThreshold.toStringAsFixed(1)} rad/s',
                  onChanged: (val) {
                    configNotifier.setAngularVelocityThreshold(val);
                  },
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Emergency Countdown Duration:'),
                    Text(
                      '${config.countdownSeconds} Seconds',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
                    ),
                  ],
                ),
                Slider(
                  value: config.countdownSeconds.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  activeColor: AppTheme.dangerColor,
                  label: '${config.countdownSeconds}s',
                  onChanged: (val) {
                    configNotifier.setCountdownSeconds(val.toInt());
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Section 3: Real Hardware Mode
          _buildSectionHeader('REAL HARDWARE MODE'),
          SwitchListTile(
            secondary: Icon(
              Icons.sensors,
              color: config.useRealHardware ? AppTheme.successColor : Colors.grey,
            ),
            title: const Text('Use Real Helmet Hardware'),
            subtitle: Text(
              config.useRealHardware
                  ? 'REAL_HARDWARE — connects to backend via Socket.IO'
                  : 'SIMULATION — uses local mock data (safe for demo)',
            ),
            value: config.useRealHardware,
            activeThumbColor: AppTheme.successColor,
            onChanged: (val) {
              configNotifier.setUseRealHardware(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val
                      ? 'Real hardware mode enabled'
                      : 'Using mock sensor and location data'),
                  backgroundColor: val ? AppTheme.successColor : AppTheme.warningColor,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge, color: AppTheme.primaryColor),
            title: const Text('Device ID'),
            subtitle: Text(config.deviceId),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showEditDialog(
              context,
              title: 'Helmet Device ID',
              initialValue: config.deviceId,
              hint: 'e.g. helmet-01',
              onSave: (val) => configNotifier.setDeviceId(val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key, color: AppTheme.warningColor),
            title: const Text('Device Token (API Key)'),
            subtitle: Text(
              config.deviceToken.isEmpty
                  ? 'Not set — required for real hardware'
                  : '••••${config.deviceToken.length > 4 ? config.deviceToken.substring(config.deviceToken.length - 4) : '••••'}',
            ),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showEditDialog(
              context,
              title: 'Device Token',
              initialValue: config.deviceToken,
              hint: 'Matches DEVICE_TOKEN in backend .env',
              obscure: true,
              onSave: (val) => configNotifier.setDeviceToken(val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.developer_board, size: 16),
              label: const Text('Open System Diagnostics'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/diagnostics');
              },
            ),
          ),
          const Divider(height: 24),

          // Section 4: Network & Gateway Configurations
          _buildSectionHeader('DISPATCH & SERVER CONFIGURATION'),
          ListTile(
            leading: const Icon(Icons.cloud_queue, color: AppTheme.primaryColor),
            title: const Text('Backend API URL'),
            subtitle: Text(config.apiBaseUrl),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showEditDialog(
              context,
              title: 'Edit Backend API URL',
              initialValue: config.apiBaseUrl,
              onSave: (val) => configNotifier.setApiBaseUrl(val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync_alt, color: AppTheme.infoColor),
            title: const Text('Socket.IO Gateway URL'),
            subtitle: Text(config.wsUrl),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showEditDialog(
              context,
              title: 'Edit Socket.IO URL',
              initialValue: config.wsUrl,
              onSave: (val) => configNotifier.setWsUrl(val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Max Responder Search Radius:'),
                    Text(
                      '${config.dispatchConfig.maxResponderDistanceKm.toStringAsFixed(0)} km',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                    ),
                  ],
                ),
                Slider(
                  value: config.dispatchConfig.maxResponderDistanceKm,
                  min: 2.0,
                  max: 30.0,
                  divisions: 28,
                  activeColor: AppTheme.warningColor,
                  label: '${config.dispatchConfig.maxResponderDistanceKm.toStringAsFixed(0)} km',
                  onChanged: (val) {
                    configNotifier.setMaxResponderDistance(val);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Section 4: Interaction Logs / Diagnostics
          _buildSectionHeader('UI INTERACTION & AUDIT LOGS'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black26
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dividerLight),
              ),
              child: uiLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No UI logs recorded yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: uiLogs.length,
                      itemBuilder: (ctx, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            uiLogs[i],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                UiLogger.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UI logs cleared')),
                );
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear Logs'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
    String? hint,
    bool obscure = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            hintText: hint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                onSave(val);
                Navigator.pop(ctx);
                if (!obscure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated $title')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title updated')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
