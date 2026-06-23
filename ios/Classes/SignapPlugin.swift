import Flutter
import Foundation
import Signap

/// Flutter plugin for the Signap iOS SDK.
///
/// Marshals the Dart `identify(config, options)` call to the native
/// `Signap` SDK (sdks/ios) — signal collection, derived ids, cert
/// pinning and the `/v1/identify` transport all run there. This plugin only
/// translates the channel dictionary ↔ the native types and bridges async ↔ the
/// Flutter result callback.
public class SignapPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "signap_signals", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SignapPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "identify" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard
            let args = call.arguments as? [String: Any],
            let config = args["config"] as? [String: Any],
            let apiKey = config["apiKey"] as? String
        else {
            result(FlutterError(code: "INVALID_CONFIGURATION", message: "apiKey is required", details: nil))
            return
        }
        let options = args["options"] as? [String: Any] ?? [:]

        var configuration = SignapConfiguration(apiKey: apiKey)
        if let endpoint = config["endpoint"] as? String, let url = URL(string: endpoint) {
            configuration.endpoint = url
        }
        if let region = config["region"] as? String {
            configuration.region = region
        }
        if let timeoutMs = config["timeoutMs"] as? Double {
            configuration.timeout = timeoutMs / 1000.0
        }
        if let pins = config["pinnedSpkiHashes"] as? [String] {
            configuration.pinnedSPKIHashes = pins
        }

        let identifyOptions = IdentifyOptions(
            linkedId: options["linkedId"] as? String,
            tag: options["tag"] as? String,
            extra: options["extra"] as? [String: String]
        )

        Task {
            do {
                let wise = try Signap(configuration: configuration)
                let r = try await wise.identify(identifyOptions)
                let payload: [String: Any] = [
                    "requestId": r.requestId,
                    "ingestedAt": r.ingestedAt,
                    "region": r.region,
                    "visitorId": r.visitorId,
                    "confidence": r.confidence,
                    "identifiedAt": r.identifiedAt,
                ]
                // FlutterResult must be invoked on the main thread.
                await MainActor.run { result(payload) }
            } catch let error as SignapError {
                let (code, message) = Self.describe(error)
                await MainActor.run { result(FlutterError(code: code, message: message, details: nil)) }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    /// Map the native error taxonomy to the bridge's stable string codes
    /// (mirrors `SignapErrorCode` on the Dart side). Messages carry NO PII.
    private static func describe(_ error: SignapError) -> (String, String) {
        switch error {
        case let .invalidConfiguration(reason):
            return ("INVALID_CONFIGURATION", reason)
        case .network:
            return ("NETWORK_ERROR", "network error")
        case .timeout:
            return ("TIMEOUT", "request timed out")
        case let .http(status):
            return ("HTTP_ERROR", "server returned \(status)")
        case .invalidResponse:
            return ("INVALID_RESPONSE", "invalid response body")
        case .pinningFailed:
            return ("PINNING_FAILED", "certificate pin mismatch")
        }
    }
}
