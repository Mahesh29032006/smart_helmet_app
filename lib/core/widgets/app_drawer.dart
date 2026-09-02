import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/emergency_providers.dart';
import '../services/ui_logger.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Navigation Drawer with links to all 8 core dashboards and screens.
class AppDrawer extends ConsumerWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyStateAsync = ref.watch(emergencyStateProvider);
    final emergencyState =
        emergencyStateAsync.asData?.value ?? ref.watch(stateMachineServiceProvider).currentState;

    final isEmergencyActive = emergencyState.isActiveEmergency;
    final config = ref.watch(appConfigProvider);
    final isRealHardware = config.useRealHardware;
    final isSocketConnected = isRealHardware ? ref.watch(isSocketConnectedProvider) : false;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEmergencyActive
                    ? [const Color(0xFFC62828), const Color(0xFFE53935)]
                    : [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEmergencyActive ? Icons.emergency : Icons.health_and_safety,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RescueLink',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Emergency Response System',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'STATUS: ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            StatusBadge.fromEmergencyState(emergencyState),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRealHardware ? 'REAL HW' : 'SIM',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  title: 'Home / Live Monitor',
                  icon: Icons.speed,
                  route: '/',
                  badge: isEmergencyActive ? 'ALERT' : null,
                ),
                _buildNavItem(
                  context,
                  title: 'Incident List',
                  icon: Icons.list_alt,
                  route: '/incidents',
                ),
                _buildNavItem(
                  context,
                  title: 'Real-Time Map',
                  icon: Icons.map,
                  route: '/map',
                ),
                const Divider(),
                _buildSectionHeader('DASHBOARDS'),
                _buildNavItem(
                  context,
                  title: 'Admin Dashboard',
                  icon: Icons.admin_panel_settings,
                  route: '/admin',
                ),
                _buildNavItem(
                  context,
                  title: 'Hospital Dashboard',
                  icon: Icons.local_hospital,
                  route: '/hospital',
                ),
                _buildNavItem(
                  context,
                  title: 'Ambulance Dashboard',
                  icon: Icons.directions_car,
                  route: '/ambulance',
                ),
                const Divider(),
                _buildSectionHeader('HARDWARE'),
                _buildNavItem(
                  context,
                  title: 'System Diagnostics',
                  icon: Icons.developer_board,
                  route: '/diagnostics',
                  badge: isRealHardware && isSocketConnected ? null : (isRealHardware ? 'OFFLINE' : null),
                ),
                const Divider(),
                _buildNavItem(
                  context,
                  title: 'Emergency Contacts',
                  icon: Icons.contacts,
                  route: '/contacts',
                ),
                _buildNavItem(
                  context,
                  title: 'Settings & Config',
                  icon: Icons.settings,
                  route: '/settings',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'v1.0.0 • Phase 7 Production',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    String? badge,
  }) {
    final isSelected = currentRoute == route;
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? primaryColor : null,
          fontSize: 14,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : (isSelected
              ? Icon(Icons.arrow_right, color: primaryColor)
              : null),
      selected: isSelected,
      selectedTileColor: primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        UiLogger.log('User navigated to $title ($route)');
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }
}
