// sdks/flutter — Flutter bridge SDK publish pipeline (M8b tail)
// Owner: Dev 7 (release run) — package config is Dev 1's (publish-ready, #1056).
//
// Publishes signap_signals to pub.dev on develop/main; dry-runs
// (flutter pub publish --dry-run) on PRs. Ahead of publish, on EVERY changeset (PR + develop/
// main), an "Android native build (example)" stage runs `flutter build apk` on
// sdks/flutter/example to COMPILE the plugin Kotlin against the real native SDK (M-3 — closes
// the gap that let the 0.1.0 bridge ship non-compiling native code). The pub.dev token comes
// from Secrets Manager via the flutter-builder agent's IRSA role — see npm-pubdev-publish.md §4.
//
// ⚠️ NOT seeded yet (commented in infra/jenkins/seed_job.groovy): (1) the flutter-builder agent
// image must carry the Flutter/Dart SDK + the Android SDK + JDK 17 (for the native-build stage)
// + awscli, (2) the jenkins-flutter-builder IRSA role needs GetSecretValue on signap/pub/*,
// (3) the pub.dev verified publisher on signap.io (or a PUB_TOKEN) must exist. Enable the seed
// entry once all three are verified (runbook §4). (The native-build gate itself needs only (1),
// no secret — but the job seeds as a whole, so it stays gated on all three.)

@Library('wise-shared') _

publishFlutterSdk(
  paths:   'sdks/flutter/**',
  // Informational; pub reads the version from pubspec.yaml — pass the tag at release time so
  // the log matches. Defaults to '0.1.0' when unset.
  version: env.SIGNAP_SDK_VERSION ?: '0.1.0',
)
