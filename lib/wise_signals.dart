/// Wise Signals — Flutter SDK (`wise_signals`).
///
/// Identifies a visitor via ingest-edge `/v1/identify`, returning the resolved
/// visitor in one round-trip. A thin bridge over the native iOS/Android SDKs
/// (see [WiseSignals]).
library wise_signals;

export 'src/types.dart' show IdentifyResult, WiseException, WiseErrorCode;
export 'src/wise_signals_base.dart' show WiseSignals;
