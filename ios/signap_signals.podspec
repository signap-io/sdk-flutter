#
# iOS side of the Signap Flutter plugin. Standard Flutter federated-plugin
# podspec. Run `flutter pub get` then build the host app to validate.
#
Pod::Spec.new do |s|
  s.name             = "signap_signals"
  s.version          = "0.1.0"
  s.summary          = "Signap — Flutter SDK (iOS bridge)."
  s.description      = "Thin Flutter bridge over the native Signap iOS SDK."
  s.homepage         = "https://github.com/wise-technology-group/wise-fingerprint-project"
  s.license      = { :type => "Apache-2.0", :file => "LICENSE" }
  s.author           = { "Wise Technology Group" => "dev@wise.example" }
  s.source           = { :path => "." }
  s.source_files     = "Classes/**/*"
  s.platform         = :ios, "14.0"
  s.swift_version    = "5.9"

  s.dependency "Flutter"

  # Native SDK dependency. The iOS SDK (sdks/ios) is currently Swift Package
  # Manager–only and NOT yet published to a public registry (brand-gated — handoff
  # M6/M7). Until a CocoaPods coordinate exists, add the `Signap` Swift
  # Package to the host app (Xcode → Package Dependencies); it links into the same
  # binary so `import Signap` in SignapPlugin.swift resolves. Once
  # M6 publishes a pod, uncomment + pin the real coordinate (brand name bakes in):
  #
  #   s.dependency "Signap", "~> 0.1"

  s.pod_target_xcconfig = { "DEFINES_MODULE" => "YES" }
end
