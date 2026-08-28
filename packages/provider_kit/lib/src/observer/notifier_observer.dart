import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/observer/change.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';

/// Observer for all ProviderKit notifiers.
///
/// Receives lifecycle callbacks for every notifier, including
/// state changes, errors, creation, and disposal.
abstract class NotifierObserver {
  const NotifierObserver();

  /// Called whenever a [notifier] is instantiated.
  @protected
  @mustCallSuper
  void onCreate(NotifierBase<dynamic> notifier) {}

  /// Called whenever a [Change] occurs in any notifier.
  /// A [change] occurs when a new state is triggered.
  /// [onChange] is called before the notifier's state is updated.  @protected
  @mustCallSuper
  void onChange(
    NotifierBase<dynamic> notifier,
    Change<dynamic> change,
  ) {}

  /// Called whenever an [error] is thrown in any notifier.
  ///
  /// The [stackTrace] argument may be [StackTrace.empty] if an error
  /// was received without a stack trace.
  @protected
  @mustCallSuper
  void onError(
    NotifierBase<dynamic> notifier,
    Object error,
    StackTrace stackTrace,
  ) {}

  /// Called whenever a [notifier] is disposed.
  ///
  /// [onDispose] is invoked just before the notifier is disposed.
  @protected
  @mustCallSuper
  void onDispose(NotifierBase<dynamic> notifier) {}
}
