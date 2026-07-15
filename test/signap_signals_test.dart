// Minimal unit tests for the signap_signals plugin's pure-Dart surface.
//
// WHY THIS EXISTS: the `wise-flutter-sdk` mirror job runs `flutter test` before
// the mirror/publish (mirrorFlutterSdk.groovy `Analyze + test`). Flutter 3.44
// (the CI agent after the C.1 bump) ERRORS on a missing `test/` dir where 3.24
// was lenient — so a package published through that pipeline must ship ≥1 test.
// `Signap.load`'s apiKey validation is real pure-Dart logic (it runs before any
// MethodChannel call), so it's assertable without a platform binding.
import 'package:flutter_test/flutter_test.dart';
import 'package:signap_signals/signap_signals.dart';

void main() {
  group('Signap.load apiKey validation', () {
    test('rejects an apiKey shorter than the 8-char minimum', () async {
      await expectLater(
        Signap.load(apiKey: 'short'),
        throwsA(
          isA<SignapException>().having(
            (e) => e.code,
            'code',
            SignapErrorCode.invalidConfiguration,
          ),
        ),
      );
    });

    test('accepts an apiKey at/above the minimum length', () async {
      expect(await Signap.load(apiKey: 'pk_live_abc123'), isA<Signap>());
    });
  });
}
