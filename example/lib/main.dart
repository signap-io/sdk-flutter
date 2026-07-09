// Example host app for the `signap_signals` Flutter plugin.
//
// Its real job is to be a compile target: `flutter build apk` / `flutter build
// ios` here compiles the plugin's native bridge against the real native SDKs, so
// CI (and the iOS release gate) catch native-wiring drift — the root cause of the
// broken 0.1.0 publish (mobile-bridge-native-wiring-handoff.md, Item 3 / M-3).
// It also drives a real `identify()` for the integration test.
import 'package:flutter/material.dart';
import 'package:signap_signals/signap_signals.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Signap Signals Example',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF4F7CFF), useMaterial3: true),
        home: const IdentifyPage(),
      );
}

/// The four states a data view must handle (ux-states-a11y): idle → loading →
/// (success | error). No fabricated data — an empty/awaiting state until a real
/// call resolves.
enum _State { idle, loading, success, error }

class IdentifyPage extends StatefulWidget {
  const IdentifyPage({super.key});

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  // The example ships NO baked endpoint/key (the SDK has no default host). Override
  // at run time to hit a real ingest, e.g.:
  //   flutter run --dart-define=SIGNAP_ENDPOINT=http://10.0.2.2:8080 \
  //               --dart-define=SIGNAP_API_KEY=pk_test_…
  static const String _endpoint = String.fromEnvironment('SIGNAP_ENDPOINT');
  static const String _apiKey =
      String.fromEnvironment('SIGNAP_API_KEY', defaultValue: 'pk_live_example0');

  _State _state = _State.idle;
  IdentifyResult? _result;
  String? _error;

  Future<void> _identify() async {
    setState(() {
      _state = _State.loading;
      _result = null;
      _error = null;
    });
    try {
      final signap = await Signap.load(
        apiKey: _apiKey,
        endpoint: _endpoint.isEmpty ? null : _endpoint,
      );
      final result = await signap.identify(linkedId: 'example-user');
      if (!mounted) return;
      setState(() {
        _state = _State.success;
        _result = result;
      });
    } on SignapException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _State.error;
        _error = '${e.code.name}: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signap Signals')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                key: const Key('identify_button'),
                onPressed: _state == _State.loading ? null : _identify,
                child: const Text('Identify'),
              ),
              const SizedBox(height: 24),
              _StatusView(state: _state, result: _result, error: _error),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.state, this.result, this.error});

  final _State state;
  final IdentifyResult? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _State.idle:
        return const Text('Tap Identify to resolve a visitor.',
            key: Key('status_idle'));
      case _State.loading:
        return const CircularProgressIndicator(key: Key('status_loading'));
      case _State.success:
        return Column(
          key: const Key('status_success'),
          children: [
            const Text('Identified', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('visitorId: ${result?.visitorId ?? ''}'),
            Text('confidence: ${result?.confidence ?? 0}'),
          ],
        );
      case _State.error:
        return Text(
          error ?? 'error',
          key: const Key('status_error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
    }
  }
}
