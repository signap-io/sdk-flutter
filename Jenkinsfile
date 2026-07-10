// sdks/flutter — Flutter bridge SDK release pipeline (M8b tail)
// Owner: Dev 7 (release run) — package config is Dev 1's (publish-ready, #1056).
//
// Jenkins does NOT publish to pub.dev directly. pub.dev is OIDC-only (no token), and GitHub Actions
// is a trusted OIDC issuer — so the release path is: gate → MIRROR sdks/flutter to the extracted
// public repo github.com/signap-io/sdk-flutter (git subtree split + force-push main + tag v<ver>) →
// the tag triggers that repo's .github/workflows/publish.yml, which OIDC-publishes to pub.dev.
// Consumers pull from pub.dev (`flutter pub add signap_signals`). Full contract:
// infra/runbooks/npm-pubdev-publish.md §3.2/§4 + docs/phase3.1/design/flutter-pubdev-gha-oidc-mirror.md.
//
// On develop/main: gates (analyze/test · Android-native example build · iOS native-build proof
// verify) then mirror + tag. On a PR: gates + `flutter pub publish --dry-run` only — never mirrors.
//
// ⚠️ NOT seeded yet (commented in infra/jenkins/seed_job.groovy). Prereqs (runbook §4): (1) the
// flutter-builder agent image carries Flutter/Dart + Android SDK + JDK 17 + git (no awscli/gcloud —
// no secret fetch, no pub token); (2) the `signap-sdk-flutter-deploy` SSH credential (write to
// signap-io/sdk-flutter) exists in Jenkins; (3) pub.dev "Automated publishing from GitHub Actions"
// is enabled on signap_signals (repo signap-io/sdk-flutter, tag v{{version}}). Enable the seed
// entry once all three are verified.

@Library('wise-shared') _

mirrorFlutterSdk(
  paths: 'sdks/flutter/**',
  // The real version is read from pubspec.yaml at mirror time (single source of truth); this is
  // informational only so the build log matches the release tag.
  version: env.SIGNAP_SDK_VERSION ?: '0.1.0',
)
