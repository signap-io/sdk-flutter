import 'package:flutter/services.dart';

import 'types.dart';

/// Entry point for the Wise Signals Flutter SDK.
///
/// A thin bridge over the native iOS (`WiseFingerprint`, sdks/ios) and Android
/// (`com.wise.fingerprint`, sdks/android) SDKs: device-signal collection,
/// cross-platform derived ids, cert pinning and the `/v1/identify` transport all
/// run in that audited native code — this layer only marshals the call across a
/// method channel. That keeps web↔iOS↔Android↔Flutter derived-id parity
/// guaranteed (one source of truth: sdks/derived-id-golden-vectors.json).
///
/// ```dart
/// final wise = await WiseSignals.load(apiKey: 'pk_live_…');
/// final result = await wise.identify(linkedId: userId);
/// debugPrint('${result.visitorId} ${result.confidence}');
/// ```
class WiseSignals {
  WiseSignals._(this._config);

  static const MethodChannel _channel = MethodChannel('wise_signals');

  /// Minimum API-key length — matched to the native SDKs' early validation so the
  /// failure mode is identical regardless of where it's caught.
  static const int _minApiKeyLength = 8;

  /// Serialized configuration passed to the native side on every identify call
  /// (the native client is constructed per-call, so it stays stateless).
  final Map<String, dynamic> _config;

  /// Validate config + return a client. Ship a PUBLIC key only (`pk_…`) — never
  /// `sk_`/management keys (a public key is protected by per-key rate-limit +
  /// quota + origin policy, not by secrecy).
  ///
  /// [endpoint] is the explicit ingest-edge base URL (the SDK appends
  /// `/v1/identify`); when null the native SDK's baked default for [region] is
  /// used. [pinnedSpkiHashes] are base64 SHA-256 SPKI pins (empty ⇒ system trust).
  static Future<WiseSignals> load({
    required String apiKey,
    String? endpoint,
    String region = 'ap',
    int timeoutMs = 5000,
    List<String> pinnedSpkiHashes = const <String>[],
  }) async {
    if (apiKey.length < _minApiKeyLength) {
      throw WiseException(
        WiseErrorCode.invalidConfiguration,
        'apiKey must be at least $_minApiKeyLength characters',
      );
    }
    return WiseSignals._(<String, dynamic>{
      'apiKey': apiKey,
      if (endpoint != null) 'endpoint': endpoint,
      'region': region,
      'timeoutMs': timeoutMs,
      'pinnedSpkiHashes': pinnedSpkiHashes,
    });
  }

  /// Collect signals (natively) and identify the visitor. [linkedId] is the
  /// strongest cross-platform linkage hint (M5): pass the logged-in user id so
  /// web + mobile sessions link to the same account. Throws a [WiseException]
  /// carrying a stable [WiseErrorCode] on failure.
  Future<IdentifyResult> identify({
    String? linkedId,
    String? tag,
    Map<String, String>? extra,
  }) async {
    try {
      final reply = await _channel.invokeMapMethod<String, dynamic>('identify', {
        'config': _config,
        'options': <String, dynamic>{
          if (linkedId != null) 'linkedId': linkedId,
          if (tag != null) 'tag': tag,
          if (extra != null) 'extra': extra,
        },
      });
      if (reply == null) {
        throw const WiseException(WiseErrorCode.invalidResponse, 'empty response from native SDK');
      }
      return IdentifyResult.fromMap(reply);
    } on PlatformException catch (e) {
      throw WiseException.fromCode(e.code, e.message ?? 'identify failed');
    }
  }
}
