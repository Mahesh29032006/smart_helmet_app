import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/incident.dart';
import '../../../core/models/location_data.dart';
import '../../../core/providers/emergency_providers.dart';
import '../../../core/services/ui_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../widgets/incident_card.dart';

/// Screen 2: Incident List Screen with multi-category filters and search.
class IncidentListScreen extends ConsumerStatefulWidget {
  const IncidentListScreen({super.key});

  @override
  ConsumerState<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends ConsumerState<IncidentListScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              UiLogger.log('User refreshed incident list');
              ref.invalidate(incidentsListProvider);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/incidents'),
      body: Column(
        children: [
          // Filter Chips & Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Theme.of(context).cardTheme.color,
            child: Column(
              children: [
                // Search Input
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Incident ID or location...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.dividerLight),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black12
                        : Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL'),
                      const SizedBox(width: 8),
                      _buildFilterChip('OPEN'),
                      const SizedBox(width: 8),
                      _buildFilterChip('DISPATCHED'),
                      const SizedBox(width: 8),
                      _buildFilterChip('IN PROGRESS'),
                      const SizedBox(width: 8),
                      _buildFilterChip('RESOLVED'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Incident List View
          Expanded(
            child: incidentsAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading incidents...'),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
                    const SizedBox(height: 12),
                    Text('Failed to load incidents: $err'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(incidentsListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (incidents) {
                final filtered = incidents.where((inc) {
                  // Filter by status
                  if (_selectedFilter != 'ALL') {
                    if (_selectedFilter == 'OPEN' && inc.status != IncidentStatus.open) {
                      return false;
                    }
                    if (_selectedFilter == 'DISPATCHED' &&
                        inc.status != IncidentStatus.dispatched) {
                      return false;
                    }
                    if (_selectedFilter == 'IN PROGRESS' &&
                        inc.status != IncidentStatus.inProgress) {
                      return false;
                    }
                    if (_selectedFilter == 'RESOLVED' &&
                        inc.status != IncidentStatus.resolved) {
                      return false;
                    }
                  }

                  // Search query matching
                  if (_searchQuery.isNotEmpty) {
                    final matchId = inc.id.toLowerCase().contains(_searchQuery);
                    final matchAddr =
                        (inc.location.address ?? '').toLowerCase().contains(_searchQuery);
                    return matchId || matchAddr;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No incidents found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try clearing your search or status filter.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final incident = filtered[index];
                    return IncidentCard(
                      incident: incident,
                      onTap: () {
                        UiLogger.log('User opened Incident Detail: ${incident.id}');
                        context.go('/incident/${incident.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          UiLogger.log('User created test emergency incident from FAB');
          final now = DateTime.now();
          final newIncident = Incident(
            id: 'inc-${now.millisecondsSinceEpoch.toString().substring(7)}',
            timestamp: now,
            location: LocationData(
              latitude: 20.2961 + (now.millisecond % 50) * 0.001,
              longitude: 85.8245 + (now.second % 50) * 0.001,
              timestamp: now,
              address: 'Khandagiri Crossing, Bhubaneswar',
            ),
            severity: IncidentSeverity.critical,
            status: IncidentStatus.open,
            crashConfidence: 0.95,
            notes: 'High acceleration delta impact logged via UI FAB.',
            metadata: {
              'peakGForce': 4.5,
              'peakAngularVelocity': 3.2,
              'trigger': 'Manual FAB trigger',
            },
          );

          await ref.read(backendApiClientProvider).createIncident(newIncident);
          ref.invalidate(incidentsListProvider);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created test incident ${newIncident.id}'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => context.go('/incident/${newIncident.id}'),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('Simulate Incident'),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
    );
  }
}
