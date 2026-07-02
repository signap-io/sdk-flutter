#
# iOS side of the Signap Flutter plugin. Standard Flutter federated-plugin
# podspec. Run `flutter pub get` then build the host app to validate.
#
Pod::Spec.new do |s|
  s.name             = "signap_signals"
  s.version          = "0.1.0"
  s.summary          = "Signap — Flutter SDK (iOS bridge)."
  s.description      = "Thin Flutter bridge over the native Signap iOS SDK."
  s.homepage         = "https://signap.io"
  s.license      = { :type => "Apache-2.0", :file => "LICENSE" }
  s.author           = { "Signap Technology" => "support@signap.io" }
  s.source           = { :path => "." }
  s.source_files     = "Classes/**/*"
  s.platform         = :ios, "14.0"
  s.swift_version    = "5.9"

  s.dependency "Flutter"

  # Native SDK dependency. The iOS SDK (sdks/ios) is published to Swift Package
  # Manager ONLY (github.com/signap-io/sdk-ios @ 0.1.0, M7 2026-07-02) — there is
  # NO CocoaPods podspec/coordinate for it. Add the `Signap` Swift Package to the
  # host app (Xcode → Package Dependencies); it links into the same binary so
  # `import Signap` in SignapPlugin.swift resolves. If a CocoaPods coordinate for
  # the native SDK is ever published, uncomment + pin it here:
  #
  #   s.dependency "Signap", "~> 0.1"

  s.pod_target_xcconfig = { "DEFINES_MODULE" => "YES" }
end
