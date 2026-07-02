# signap_signals — Flutter SDK (alpha)

> Cross-platform Flutter SDK that identifies a visitor in one round-trip,
> returning the resolved visitor id + confidence. Apache-2.0.

## Architecture — a thin native bridge (not a re-implementation)

This SDK is a **bridge**: every Dart `identify()` call is marshalled over a method
channel to the audited **native SDKs** — iOS `Signap` and Android `io.signap.sdk`.
Device-signal collection, the cross-platform **derived ids**
(`supplementary_id`/`proximity_id`), cert pinning and the `/v1/identify` transport
all run in that native code.

Why bridge instead of re-implementing in Dart:

- **Parity is guaranteed.** Derived-id parity is locked across web↔iOS↔Android by a
  single shared golden fixture. Bridging means Flutter lands in the **same** visitor
  bucket as the native apps — re-deriving in Dart would risk the drift the fixture
  exists to prevent.
- **Full device signals.** `deviceModel`, `osVersion`, `vendorId`, `isEmulator`,
  `isRooted`, RAM/cores need native APIs anyway; the native SDKs already collect
  them with zero third-party deps.

## Install

```yaml
# pubspec.yaml
dependencies:
  signap_signals: ^0.1.0
```

## Usage

```dart
import 'package:signap_signals/signap_signals.dart';

// Configure once (e.g. in main() or initState). Ship a PUBLIC key only (pk_…).
// `endpoint` is REQUIRED — the SDK ships no baked default host.
final signap = await Signap.load(
  apiKey: 'pk_live_xxxxxxxx',
  endpoint: 'https://your-ingest-host.example', // required (e.g. http://10.0.2.2:8080 → a local dev server from the Android emulator)
  region: 'ap',
);

// Identify. `linkedId` is the cross-platform linkage hint: pass the logged-in
// user id so web + mobile sessions link to the same account.
final result = await signap.identify(linkedId: currentUserId);
debugPrint('${result.visitorId} ${result.confidence}');
```

Failures throw a typed `SignapException` with a stable `code` (a `SignapErrorCode`:
`invalidConfiguration` · `network` · `timeout` · `http` · `invalidResponse` ·
`pinningFailed`); for `http` the HTTP `status` is also set.

### Cert pinning (production)

```dart
final signap = await Signap.load(
  apiKey: 'pk_live_xxxxxxxx',
  pinnedSpkiHashes: ['base64-sha256-of-server-SPKI'], // empty ⇒ system trust (dev)
);
```

The pin is the **SHA-256 of the SubjectPublicKeyInfo (SPKI) DER** — the standard
form, **identical on web / iOS / Android** (one pin for all platforms). It is
enforced by the native SDK. Compute it from the server cert:

```bash
openssl x509 -in server.crt -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary | base64
```

## API

| Member | Signature | Notes |
|---|---|---|
| `Signap.load(...)` | `Future<Signap>` | Named args: `apiKey`, `endpoint?`, `region`, `timeoutMs`, `pinnedSpkiHashes`. Validates `apiKey` (≥ 8 chars). |
| `signap.identify(...)` | `Future<IdentifyResult>` | Named args: `linkedId?`, `tag?`, `extra?`. Collects signals natively + resolves the visitor. |

`IdentifyResult`: `{ requestId, ingestedAt, region, visitorId, confidence, identifiedAt }`

These mirror the native iOS/Android types one-to-one (the method channel marshals
maps ↔ native types).

## Native dependency

The bridge calls into the native SDKs:

- **iOS** — the `Signap` Swift package links into your app binary so `import Signap`
  in the plugin resolves; the podspec
  ([`ios/signap_signals.podspec`](./ios/signap_signals.podspec)) wires it.
- **Android** — depends on the `io.signap.sdk` Maven artifact via
  [`android/build.gradle`](./android/build.gradle).

## What it sends

The native SDK builds a proto3-JSON `FingerprintPayload` (with a native
`MobileSignals` block) — the **same wire shape** as the native iOS/Android apps,
reported with the underlying native SDK's `x-sdk-name`
(`@signap/signals-ios` / `@signap/signals-android`).

## Status

Alpha. Public API + native bridge are final.

## License

Apache-2.0 — see [`LICENSE`](LICENSE).
