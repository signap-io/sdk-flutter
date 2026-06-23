# wise_signals — Flutter SDK (alpha)

> Cross-platform Flutter SDK that identifies a visitor via ingest-edge
> `/v1/identify`, returning the resolved visitor in one round-trip.
>
> Owner: **Dev 1** · Phase 3 Theme B · **dev-live, alpha**
> Wire contract: [`libs/proto/.../identify.proto`](../../libs/proto/wisefingerprint/identify/v1/identify.proto)
> + the mobile envelope spec [`docs/phase3/design/mobile-identify-envelope.md`](../../docs/phase3/design/mobile-identify-envelope.md) (M1).

## Architecture — a thin native bridge (not a re-implementation)

This SDK is a **bridge**: every Dart `identify()` call is marshalled over a method
channel to the audited **native SDKs** — [iOS `WiseFingerprint`](../ios) and
[Android `com.wise.fingerprint`](../android). Device-signal collection, the
cross-platform **derived ids** (`supplementary_id`/`proximity_id`), cert pinning
and the `/v1/identify` transport all run in that native code.

Why bridge instead of re-implementing in Dart:

- **Parity is guaranteed.** Derived-id parity is locked across web↔iOS↔Android by
  a single golden fixture ([`sdks/derived-id-golden-vectors.json`](../derived-id-golden-vectors.json)).
  Bridging means Flutter lands in the **same** visitor bucket as the native apps —
  re-deriving in Dart would risk the drift the fixture exists to prevent.
- **Full device signals.** `deviceModel`, `osVersion`, `vendorId`, `isEmulator`,
  `isRooted`, RAM/cores need native APIs anyway; the native SDKs already collect
  them with zero third-party deps.

## Install

> ⚠️ **Not published yet.** The mobile SDKs are brand-gated (handoff M6/M7) — there
> is no public pub.dev coordinate or native package coordinate yet. The integration
> code below is **final**; the install step lands once the packages publish (the
> Get Started → Mobile → Flutter flow flips automatically). For now, consume in-repo
> via a path dependency and link the native SDKs locally (see
> [Native dependency](#native-dependency)).

```yaml
# pubspec.yaml — coming soon (M8b):
dependencies:
  wise_signals: ^0.1.0

# in-repo for now:
dependencies:
  wise_signals:
    path: ../wise-fingerprint-project/sdks/flutter
```

## Usage

```dart
import 'package:wise_signals/wise_signals.dart';

// Configure once (e.g. in main() or initState). Ship a PUBLIC key only (pk_…).
final wise = await WiseSignals.load(
  apiKey: 'pk_live_xxxxxxxx',
  // endpoint: 'http://10.0.2.2:8080', // Android emulator → host `make dev`
  region: 'ap',                         // baked default otherwise
);

// Identify. `linkedId` is the cross-platform linkage hint (M5): pass the
// logged-in user id so web + mobile sessions link to the same account.
final result = await wise.identify(linkedId: currentUserId);
debugPrint('${result.visitorId} ${result.confidence}');
```

Failures throw a typed `WiseException` with a stable `code` (a `WiseErrorCode`:
`invalidConfiguration` · `network` · `timeout` · `http` · `invalidResponse` ·
`pinningFailed`); for `http` the HTTP `status` is also set.

### Cert pinning (production)

```dart
final wise = await WiseSignals.load(
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
| `WiseSignals.load(...)` | `Future<WiseSignals>` | Named args: `apiKey`, `endpoint?`, `region`, `timeoutMs`, `pinnedSpkiHashes`. Validates `apiKey` (≥ 8 chars). |
| `wise.identify(...)` | `Future<IdentifyResult>` | Named args: `linkedId?`, `tag?`, `extra?`. Collects signals natively + resolves the visitor. |

`IdentifyResult`: `{ requestId, ingestedAt, region, visitorId, confidence, identifiedAt }`

These mirror the native iOS/Android types one-to-one (the method channel marshals
maps ↔ native types).

## Native dependency

The bridge calls into the native SDKs, which are **not yet published**:

- **iOS** — the [iOS SDK](../ios) is currently Swift Package Manager–only. Add the
  `WiseFingerprint` package to your app (Xcode → *Package Dependencies*); it links
  into the same binary so `import WiseFingerprint` in the plugin resolves. Once a
  CocoaPods coordinate ships (M6), it moves into [`ios/wise_signals.podspec`](./ios/wise_signals.podspec).
- **Android** — the [Android SDK](../android) is not yet on Maven Central. For
  in-repo dev, wire it via a Gradle composite build; once published (M6), depend on
  the real coordinate in [`android/build.gradle`](./android/build.gradle).

## What it sends

The native SDK builds a proto3-JSON `FingerprintPayload` (with the additive
`MobileSignals` block, M1) — the **same wire shape** as the native iOS/Android
apps, reported with the underlying native SDK's `x-sdk-name`
(`@wise/signals-ios` / `@wise/signals-android`). See the
[iOS](../ios/README.md) / [Android](../android/README.md) READMEs for the full
field list.

## Status

Alpha. Public API + native bridge are final; **publish + the install coordinate are
brand-gated** (handoff M6/M7 → M8b). See
[`docs/phase3/status/dev-1.md`](../../docs/phase3/status/dev-1.md).
