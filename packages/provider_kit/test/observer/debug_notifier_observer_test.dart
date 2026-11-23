import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../shared/mocks/notifiers.dart';

void main() {
  group('DebugNotifierObserver', () {
    late DebugNotifierObserver observer;
    late StateNotifier<int> notifier;
    late List<String> logs;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      observer = DebugNotifierObserver();
      notifier = TestStateNotifier<int>(0);
      logs = [];

      originalDebugPrint = debugPrint;

      debugPrint = (message, {wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
      notifier.dispose();
    });

    test('logs notifier creation', () {
      observer.onCreate(notifier);

      expect(logs, ['[ProviderKit] Created: ${notifier.runtimeType}']);
    });

    test('logs state changes', () {
      const change = Change<int>(currentState: 0, nextState: 1);

      observer.onChange(notifier, change);

      expect(logs, [
        '[ProviderKit] ${notifier.runtimeType}: int → int',
        '  Previous: 0',
        '  Current:  1',
      ]);
    });

    test('logs notifier errors and stack traces', () {
      final error = StateError('Test error');
      final stackTrace = StackTrace.current;

      observer.onError(notifier, error, stackTrace);

      expect(logs, [
        '[ProviderKit] Error in ${notifier.runtimeType}: $error',
        stackTrace.toString(),
      ]);
    });

    test('logs notifier disposal', () {
      observer.onDispose(notifier);

      expect(logs, ['[ProviderKit] Disposed: ${notifier.runtimeType}']);
    });
  });
}
