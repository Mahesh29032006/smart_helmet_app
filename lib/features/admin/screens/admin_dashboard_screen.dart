import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/incident.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../incidents/widgets/incident_card.dart';
import '../widgets/metrics_card.dart';

/// Screen 5: Admin Dashboard for global emergency metrics, active incidents, and fleet status.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsListProvider);
    final activeIncidentsAsync = ref.watch(activeIncidentsProvider);
    final responder = ref.watch(assignedResponderProvider);
    final hospital = ref.watch(assignedHospitalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'System Settings',
            onPressed: () {
              UiLogger.log('User opened settings from admin');
              context.go('/settings');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Executive Metrics 2x2 Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: incidentsAsync.when(
                loading: () => const LoadingIndicator(message: 'Calculating metrics...'),
                error: (error, stack) => const SizedBox.shrink(),
                data: (allIncidents) {
                  final activeCount = allIncidents
                      .where((i) =>
                          i.status == IncidentStatus.open ||
                          i.status == IncidentStatus.dispatched ||
                          i.status == IncidentStatus.inProgress)
                      .length;

                  final resolvedCount =
                      allIncidents.where((i) => i.status == IncidentStatus.resolved).length;
                  final totalToday = allIncidents.length;
                  final resolveRate = totalToday > 0
                      ? ((resolvedCount / totalToday) * 100).toStringAsFixed(0)
                      : '100';

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MetricsCard(
                              title: 'ACTIVE INCIDENTS',
                              value: '$activeCount',
                              subtitle: activeCount > 0 ? 'Urgent attention required' : 'All clear',
                              icon: Icons.emergency,
                              color: activeCount > 0 ? AppTheme.dangerColor : AppTheme.successColor,
                              onTap: () => context.go('/incidents'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricsCard(
                              title: 'AVG RESPONSE TIME',
                              value: '4.2 min',
                              subtitle: 'Target: < 8.0 min (Met)',
                              icon: Icons.timer,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MetricsCard(
                              title: 'TOTAL TODAY',
                              value: '$totalToday',
                              subtitle: '$resolvedCount resolved',
                              icon: Icons.bar_chart,
                              color: AppTheme.infoColor,
                              onTap: () => context.go('/incidents'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricsCard(
                              title: 'RESOLUTION RATE',
                              value: '$resolveRate%',
                              subtitle: 'SLA: 98% compliant',
                              icon: Icons.verified,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        UiLogger.log('User navigated to Map from Admin');
                        context.go('/map');
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Live Map'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        UiLogger.log('Admin triggered test crash event');
                        ref.read(sensorSimulatorProvider).injectCrashEvent();
                        context.go('/');
                      },
                      icon: const Icon(Icons.warning_amber, size: 18),
                      label: const Text('Trigger Test SOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fleet & Infrastructure Status
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Active Response Fleet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildFleetRow(
                        responder?.name ?? 'Ambulance A1 (Advance Life Support)',
                        responder?.vehicleNumber ?? 'OD-02-EM-1081',
                        responder?.status.name.toUpperCase() ?? 'AVAILABLE',
                        Icons.airport_shuttle,
                        AppTheme.primaryColor,
                      ),
                      const Divider(height: 16),
                      _buildFleetRow(
                        hospital?.name ?? 'City Trauma Centre & Multi-speciality',
                        'Level-1 Trauma Hub',
                        'STANDBY (4 BEDS FREE)',
                        Icons.local_hospital,
                        AppTheme.successColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Active Incidents Stream List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Emergency Incidents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/incidents'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            activeIncidentsAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading active incidents...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (activeList) {
                if (activeList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Card(
                      color: AppTheme.successLight.withValues(alpha: 0.4),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.successColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No active emergency incidents right now. All units on standby.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: activeList.map((inc) {
                    return IncidentCard(
                      incident: inc,
                      onTap: () => context.go('/incident/${inc.id}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetRow(
    String name,
    String detail,
    String status,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                detail,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
