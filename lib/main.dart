import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/emergency_providers.dart';
import 'core/routes/app_router.dart';
import 'core/services/ui_logger.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Global Error Boundary and Exception Logging
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    UiLogger.log('[Framework Error] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    UiLogger.log('[Async Error] $error');
    return true;
  };

  UiLogger.log('RescueLink Emergency System Initialized');
  runApp(const ProviderScope(child: EmergencyResponseApp()));
}

/// Root Application Widget with Riverpod, GoRouter, and Theme.
class EmergencyResponseApp extends ConsumerStatefulWidget {
  const EmergencyResponseApp({super.key});

  @override
  ConsumerState<EmergencyResponseApp> createState() =>
      _EmergencyResponseAppState();
}

class _EmergencyResponseAppState extends ConsumerState<EmergencyResponseApp> {
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _initializeBackgroundServices();
    _checkDemoMode();
  }

  /// Warm up background crash detection and telemetry pipeline on startup
  void _initializeBackgroundServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(appConfigProvider);
      // Warm up state machine
      ref.read(stateMachineServiceProvider);
      if (!config.useRealHardware) {
        ref.read(crashDetectionServiceProvider);
        UiLogger.log('Simulation telemetry and crash detection pipelines active');
      } else {
        ref.read(realTimeDataServiceProvider);
        UiLogger.log('Real hardware telemetry pipeline active');
      }
    });
  }

  void _checkDemoMode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(appConfigProvider);
      if (!config.useRealHardware && config.demoMode) {
        final state = ref.read(stateMachineServiceProvider).currentState;
        if (!state.isActiveEmergency) {
          UiLogger.log('Demo mode active: auto-triggering crash in ${config.demoDelaySeconds}s');
          _demoTimer?.cancel();
          _demoTimer = Timer(Duration(seconds: config.demoDelaySeconds), () {
            UiLogger.log('Demo mode timer expired: auto-triggering simulated crash');
            ref.read(sensorSimulatorProvider).injectCrashEvent(
                  gForce: 5.2,
                  rollRadS: 4.0,
                );
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch reactive theme mode from Riverpod
    final themeMode = ref.watch(themeModeProvider);

    // Listen for demoMode config changes
    ref.listen(appConfigProvider, (previous, next) {
      if (next.demoMode && !(previous?.demoMode ?? false)) {
        final state = ref.read(stateMachineServiceProvider).currentState;
        if (!state.isActiveEmergency) {
          _demoTimer?.cancel();
          _demoTimer = Timer(Duration(seconds: next.demoDelaySeconds), () {
            UiLogger.log('Demo mode timer expired: auto-triggering crash');
            ref.read(sensorSimulatorProvider).injectCrashEvent();
          });
        }
      } else if (!next.demoMode) {
        _demoTimer?.cancel();
      }
    });

    return MaterialApp.router(
      title: 'RescueLink Emergency Response',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
