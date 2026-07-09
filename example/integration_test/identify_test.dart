// On-device integration test: taps Identify and asserts the app reaches a
// terminal state (success OR error). Reaching either proves the Dart→platform-
// channel→native-bridge round-trip works — i.e. the native SDK is actually linked
// (the exact wiring the broken 0.1.0 publish lacked). Run on a device/emulator:
//   flutter test integration_test
// With a live ingest it resolves a visitor; with none it surfaces a typed error —
// both are terminal, both prove the native bridge is wired.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signap_signals_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Identify reaches a terminal state (native bridge wired)',
      (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.byKey(const Key('status_idle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('identify_button')));
    await tester.pump(); // kick off loading

    // Poll for a terminal state (success or error) — the native call is async.
    var settled = false;
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const Key('status_success')).evaluate().isNotEmpty ||
          find.byKey(const Key('status_error')).evaluate().isNotEmpty) {
        settled = true;
        break;
      }
    }

    expect(settled, isTrue,
        reason: 'identify() never reached success/error — native bridge likely not linked');
  });
}
