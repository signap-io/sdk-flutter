# signap_signals — example app

Host app for the `signap_signals` Flutter plugin. Its primary purpose is to be a
**native compile target**: building it compiles the plugin's Kotlin/Swift bridge
against the **real** native SDKs, so CI (and the iOS release gate) catch
native-wiring drift — the root cause of the broken `0.1.0` publish
([`mobile-bridge-native-wiring-handoff.md`](../../../docs/phase3.1/design/mobile-bridge-native-wiring-handoff.md),
Item 3 / M-3).

## Build (the CI gate)

```bash
flutter build apk    # Android: compiles the bridge vs io.signap.sdk:signals (Maven Central)
flutter build ios    # iOS: needs the M-2 SPM wiring + a Mac with Xcode
```

## Run against a real ingest

The SDK ships **no baked host** — pass one at run time:

```bash
flutter run \
  --dart-define=SIGNAP_ENDPOINT=http://10.0.2.2:8080 \
  --dart-define=SIGNAP_API_KEY=pk_test_…
```

(`10.0.2.2` reaches a `localhost` dev server from the Android emulator.) Without an
endpoint the app still runs and surfaces a typed configuration error — a terminal
state that proves the native bridge is linked.

## Integration test

```bash
flutter test integration_test   # needs a device/emulator
```

`integration_test/identify_test.dart` taps **Identify** and asserts the app reaches
a terminal state (success or a typed error) — either outcome proves the
Dart→platform-channel→native round-trip works.
