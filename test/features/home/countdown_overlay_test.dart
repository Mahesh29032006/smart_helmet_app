import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_response_app/features/home/widgets/countdown_overlay.dart';

void main() {
  group('CountdownOverlay Widget Tests', () {
    testWidgets('Displays timer countdown number and cancel button', (tester) async {
      bool cancelled = false;
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownOverlay(
              countdownSeconds: 8,
              onCancel: () => cancelled = true,
              onConfirm: () => confirmed = true,
            ),
          ),
        ),
      );

      // Verify countdown number
      expect(find.text('8'), findsOneWidget);
      expect(find.text('CRASH DETECTED - AUTOMATIC SOS'), findsOneWidget);
      expect(find.text("I'M OK - CANCEL SOS"), findsOneWidget);
      expect(find.text('SEND HELP IMMEDIATELY'), findsOneWidget);

      // Tap Cancel Button
      await tester.tap(find.text("I'M OK - CANCEL SOS"));
      await tester.pump();
      expect(cancelled, isTrue);

      // Tap Confirm Button
      await tester.tap(find.text('SEND HELP IMMEDIATELY'));
      await tester.pump();
      expect(confirmed, isTrue);
    });
  });
}
