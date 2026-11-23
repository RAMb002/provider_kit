import 'package:flutter/foundation.dart';
import 'package:provider_kit/provider_kit.dart';

class DebugNotifierObserver extends NotifierObserver {
  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);

    debugPrint('[ProviderKit] Created: ${notifier.runtimeType}');
  }

  @override
  void onChange(NotifierBase notifier, Change change) {
    super.onChange(notifier, change);

    debugPrint(
      '[ProviderKit] ${notifier.runtimeType}: '
      '${change.currentState.runtimeType} '
      '→ ${change.nextState.runtimeType}',
    );

    debugPrint('  Previous: ${change.currentState}');

    debugPrint('  Current:  ${change.nextState}');
  }

  @override
  void onError(NotifierBase notifier, Object error, StackTrace stackTrace) {
    super.onError(notifier, error, stackTrace);

    debugPrint('[ProviderKit] Error in ${notifier.runtimeType}: $error');

    debugPrint(stackTrace.toString());
  }

  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);

    debugPrint('[ProviderKit] Disposed: ${notifier.runtimeType}');
  }
}
