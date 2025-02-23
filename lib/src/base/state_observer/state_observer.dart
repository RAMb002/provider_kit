import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/state_notifier_base.dart';
import 'package:provider_kit/src/base/state_observer/change.dart';

abstract class StateObserver {
  const StateObserver();

  /// Called whenever a [stateNotifier] is instantiated.
  @protected
  @mustCallSuper
  void onCreate(StateNotifierBase<dynamic> stateNotifier) {}

  /// Called whenever a [Change] occurs in any [StateNotifier]
  /// A [change] occurs when a new state is triggered.
  /// [onChange] is called before a stateNotifier's state has been updated.
  @protected
  @mustCallSuper
  void onChange(
      StateNotifierBase<dynamic> stateNotifier, Change<dynamic> change) {}

  /// Called whenever an [error] is thrown in any [StateNotifier].
  /// The [stackTrace] argument may be [StackTrace.empty] if an error
  /// was received without a stack trace.
  @protected
  @mustCallSuper
  void onError(StateNotifierBase<dynamic> stateNotifier, Object error,
      StackTrace stackTrace) {}

  /// Called whenever a [stateNotifier] is dispose.
  /// [onDispose] is called just before the [stateNotifier] is disposed
  @protected
  @mustCallSuper
  void onDispose(StateNotifierBase<dynamic> stateNotifier) {}
}
