import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';


class NotifierLogger extends StateObserver {
  @override
  void onChange(StateNotifierBase stateNotifier, Change change) {
    super.onChange(stateNotifier, change);
    debugPrint(
      'stateNotifier onChange -- ${stateNotifier.runtimeType}, ${change.currentState.runtimeType} ---> ${change.nextState.runtimeType}',
    );
  }

  @override
  void onCreate(StateNotifierBase stateNotifier) {
    super.onCreate(stateNotifier);

    debugPrint('stateNotifier onCreate -- ${stateNotifier.runtimeType}');
  }

  @override
  void onError(
      StateNotifierBase stateNotifier, Object error, StackTrace stackTrace) {
    debugPrint(
        'stateNotifier onError -- ${stateNotifier.runtimeType} ${"error - $error"} ${"stackTrace - $stackTrace"}');
    super.onError(stateNotifier, error, stackTrace);
  }

  @override
  void onDispose(StateNotifierBase stateNotifier) {
    super.onDispose(stateNotifier);

    debugPrint('stateNotifier onClose -- ${stateNotifier.runtimeType}');
  }
}
