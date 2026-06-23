/// Public types for the Signap Flutter SDK. These mirror the native iOS
/// `SignapConfiguration`/`IdentifyOptions`/`IdentifyResult` (sdks/ios) and the
/// Android equivalents (sdks/android) — the Flutter SDK is a thin bridge that
/// delegates to those native SDKs, so the shapes stay in lockstep.

/// Resolved visitor identity returned by `Signap.identify`. Wire shape =
/// ingest-edge's `IngestResponse` (sync-inline): the edge resolves the visitor
/// before responding.
class IdentifyResult {
  const IdentifyResult({
    required this.requestId,
    required this.ingestedAt,
    required this.region,
    required this.visitorId,
    required this.confidence,
    required this.identifiedAt,
  });

  final String requestId;
  final String ingestedAt;
  final String region;
  final String visitorId;
  final double confidence;
  final String identifiedAt;

  /// Build from the platform-channel reply (a `Map` of dynamics).
  factory IdentifyResult.fromMap(Map<String, dynamic> map) {
    return IdentifyResult(
      requestId: map['requestId'] as String? ?? '',
      ingestedAt: map['ingestedAt'] as String? ?? '',
      region: map['region'] as String? ?? '',
      visitorId: map['visitorId'] as String? ?? '',
      // Native sends a double; tolerate an int-encoded 0/1 just in case.
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      identifiedAt: map['identifiedAt'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'IdentifyResult(visitorId: $visitorId, confidence: $confidence, region: $region)';
}

/// Stable error taxonomy. Mirrors the native iOS `SignapError` / Android
/// `SignapException` cases (mapped from the platform-channel error code) and the
/// web `SdkError` codes.
enum SignapErrorCode {
  invalidConfiguration,
  network,
  timeout,
  http,
  invalidResponse,
  pinningFailed,
}

/// Maps the bridge's stable string codes ↔ [SignapErrorCode]. The strings match
/// the codes the native plugins reject with (see SignapPlugin.{swift,kt}).
const Map<String, SignapErrorCode> _codeFromString = {
  'INVALID_CONFIGURATION': SignapErrorCode.invalidConfiguration,
  'NETWORK_ERROR': SignapErrorCode.network,
  'TIMEOUT': SignapErrorCode.timeout,
  'HTTP_ERROR': SignapErrorCode.http,
  'INVALID_RESPONSE': SignapErrorCode.invalidResponse,
  'PINNING_FAILED': SignapErrorCode.pinningFailed,
};

/// Error thrown by `Signap.load` / `Signap.identify`. Messages carry
/// NO PII (mirrors the native taxonomy).
class SignapException implements Exception {
  const SignapException(this.code, this.message, {this.status});

  final SignapErrorCode code;
  final String message;

  /// HTTP status when [code] is [SignapErrorCode.http], else null.
  final int? status;

  /// Build from a platform-channel error `code` string (unknown ⇒ network).
  factory SignapException.fromCode(String code, String message) {
    final mapped = _codeFromString[code] ?? SignapErrorCode.network;
    int? status;
    if (mapped == SignapErrorCode.http) {
      // The native HTTP reject embeds the status in the message ("server
      // returned 429"); surface it when parseable.
      final match = RegExp(r'\b(\d{3})\b').firstMatch(message);
      if (match != null) status = int.tryParse(match.group(1)!);
    }
    return SignapException(mapped, message, status: status);
  }

  @override
  String toString() => 'SignapException(${code.name}: $message)';
}
