import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class NotifierLogger extends NotifierObserver {
  @override
  void onChange(NotifierBase notifier, Change change) {
    super.onChange(notifier, change);
    debugPrint(
      'notifier onChange -- ${notifier.runtimeType}, ${change.currentState.runtimeType} ---> ${change.nextState.runtimeType}',
    );
  }

  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);

    debugPrint('notifier onCreate -- ${notifier.runtimeType}');
  }

  @override
  void onError(
      NotifierBase notifier, Object error, StackTrace stackTrace) {
    debugPrint(
        'notifier onError -- ${notifier.runtimeType} ${"error - $error"} ${"stackTrace - $stackTrace"}');
    super.onError(notifier, error, stackTrace);
  }

  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);

    debugPrint('notifier onDispose -- ${notifier.runtimeType}');
  }
}
