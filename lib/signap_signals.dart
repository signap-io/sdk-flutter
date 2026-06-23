/// Signap — Flutter SDK (`signap_signals`).
///
/// Identifies a visitor via ingest-edge `/v1/identify`, returning the resolved
/// visitor in one round-trip. A thin bridge over the native iOS/Android SDKs
/// (see [Signap]).
library signap_signals;

export 'src/types.dart' show IdentifyResult, SignapException, SignapErrorCode;
export 'src/signap_signals_base.dart' show Signap;
