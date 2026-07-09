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
  # Source moved under the SPM package dir (signap_signals/Sources/…) for the dual
  # pod+SPM layout; the podspec points at the same files for CocoaPods consumers.
  s.source_files     = "signap_signals/Sources/signap_signals/**/*.swift"
  s.platform         = :ios, "14.0"
  s.swift_version    = "5.9"

  s.dependency "Flutter"

  # Native SDK dependency (CocoaPods path). The native iOS SDK ships to SPM
  # (github.com/signap-io/sdk-ios @ 0.1.0) AND, for CocoaPods consumers, as the pod
  # `SignapSDK` (Dev-7 publishes it — coordinate is `SignapSDK` to avoid colliding
  # with the RN bridge pod named `Signap`, but its module_name stays `Signap` so
  # `import Signap` in SignapPlugin.swift is unchanged). SPM consumers get the same
  # module via Package.swift. See ios-spm-publish.md §6.5.
  s.dependency "SignapSDK", "0.1.0"

  s.pod_target_xcconfig = { "DEFINES_MODULE" => "YES" }
end
