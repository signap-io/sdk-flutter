// swift-tools-version: 5.9
// Swift Package Manager manifest for the Signap Flutter plugin's iOS side.
//
// Flutter 3.44 supports SPM plugins (dual pod+SPM — the sibling
// signap_signals.podspec is kept for CocoaPods consumers). This resolves the
// native iOS SDK (`Signap`) as a real package dependency, so `import Signap` in
// SignapPlugin.swift links WITHOUT any host-app wiring — the fix for the 0.1.0
// bridge, whose CocoaPods plugin could not see the SPM-only native module
// (mobile-bridge-ios-spm-plan.md §2).
import PackageDescription

let package = Package(
    name: "signap_signals",
    platforms: [
        .iOS("14.0"),
    ],
    products: [
        // Library name uses hyphens, target keeps underscores (Flutter SPM guide).
        .library(name: "signap-signals", targets: ["signap_signals"]),
    ],
    dependencies: [
        // Flutter-generated at build time (required by the Flutter SPM plugin layout).
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Native iOS SDK — SPM-only, product "Signap". Exact-pinned to the published
        // tag so a plugin build can't silently drift onto an unpublished native change.
        .package(url: "https://github.com/signap-io/sdk-ios", exact: "0.1.0"),
    ],
    targets: [
        .target(
            name: "signap_signals",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Signap", package: "sdk-ios"),
            ]
        ),
    ]
)
