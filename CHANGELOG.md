# Changelog

## 0.1.1

- Fix native wiring so the bridge actually compiles against the native SDKs
  (0.1.0 shipped an Android/iOS side that never built against them):
  - Android: declare the `io.signap.sdk:signals:0.1.0` dependency + import the
    native `Signap` factory (M-1).
  - iOS: migrate the plugin to a Swift Package Manager manifest that resolves the
    native `Signap` module from `sdk-ios@0.1.0`, so `import Signap` resolves with
    no manual host-app wiring (M-2).
- Native iOS/Android SDKs are unchanged (still 0.1.0) — this is a bridge-only fix.

## 0.1.0

- Initial release. Signap Flutter SDK — a thin bridge over the native iOS/Android
  SDKs for visitor identification and cross-platform stitching. Delegates to the
  audited native SDKs (no re-implemented signal / derived-id logic).
