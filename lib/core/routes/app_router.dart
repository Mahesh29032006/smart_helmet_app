import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/ambulance/screens/ambulance_dashboard_screen.dart';
import '../../features/diagnostics/screens/diagnostics_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/hospital/screens/hospital_dashboard_screen.dart';
import '../../features/incidents/screens/incident_detail_screen.dart';
import '../../features/incidents/screens/incident_list_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/contacts_screen.dart';

/// Central GoRouter configuration with all application dashboard routes.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/incidents',
      builder: (context, state) => const IncidentListScreen(),
    ),
    GoRoute(
      path: '/incident/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'inc-101';
        return IncidentDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/hospital',
      builder: (context, state) => const HospitalDashboardScreen(),
    ),
    GoRoute(
      path: '/ambulance',
      builder: (context, state) => const AmbulanceDashboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/diagnostics',
      builder: (context, state) => const DiagnosticsScreen(),
    ),
  ],
);
