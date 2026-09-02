import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/core/providers/emergency_providers.dart';
import 'package:emergency_response_app/core/widgets/app_drawer.dart';

void main() {
  testWidgets('AppDrawer builds with real hardware without crashing', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(appConfigNotifierProvider.notifier).setUseRealHardware(true);
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(currentRoute: '/'),
          ),
        ),
      ),
    );
    
    // Open drawer
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();
    
    expect(find.byType(AppDrawer), findsOneWidget);
  });
}
