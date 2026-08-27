part of '../core/provider_kit_core.dart';


/// The foundation for all notifiers in this package.
///
/// [NotifierBase] centralises lifecycle and observer behaviour shared by every
/// notifier implementation – including state change notification, error
/// reporting, disposal, and Flutter memory allocation tracking.
///
/// **This class is internal and not intended to be used directly by end users.**
///
/// Instead of extending [NotifierBase], you should extend one of the concrete
/// notifier implementations provided by this package, such as:
///
/// - [StateNotifier] – for simple value state management.
/// - [AsyncViewStateNotifier] – for asynchronous view‑state fetching.
/// - Future notifier types (e.g., mutations) – will also be built on this base.
///
/// ### Observing notifier lifecycle events
///
/// To monitor all notifiers globally, assign an implementation of
/// [NotifierObserver] to the static [observer] field:
///
/// ```dart
/// NotifierBase.observer = MyCustomObserver();
/// ```
///
/// This observer will receive `onCreate`, `onChange`, `onError`, and `onDispose`
/// events for every notifier in your application.
///
/// ### Subclassing guidelines
///
/// If you do need to create a custom notifier, always:
/// - Call `super.onCreate(this)` in your constructor (handled by the base).
/// - Call `super.onChange(change)` first in any override of `onChange`.
/// - Call `super.onError(error, stackTrace)` last in any override of `onError`.
/// - Call `super.dispose()` in your `dispose` method.
///
/// See also:
/// - [NotifierObserver] – the interface for global observers.
/// - [Change] – the data object passed on state transitions.
abstract class NotifierBase<State> extends ChangeNotifier {
  /// Creates a [NotifierBase].
  ///
  /// Registers the notifier with the global [NotifierObserver] and dispatches
  /// Flutter memory allocation events when enabled.
  NotifierBase() {
    // ignore: invalid_use_of_protected_member
    _observer.onCreate(this);

    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  /// The global observer used to monitor notifier lifecycle events.
  static NotifierObserver _observer = const _DefaultNotifierObserver();

  bool _disposed = false;

  /// Whether this notifier is still active.
  ///
  /// This is useful for asynchronous notifiers to avoid updating state after
  /// they have been disposed.
  @protected
  bool get mounted => !_disposed;

  /// Throws a descriptive assertion if this notifier has already been disposed.
  ///
  /// Mirrors Flutter's `ChangeNotifier.debugAssertNotDisposed`.
  @protected
  static bool debugAssertNotDisposed(NotifierBase<dynamic> notifier,
      [String? operation]) {
    assert(() {
      if (notifier._disposed) {
        throw FlutterError(
          '\n'
          'A ${notifier.runtimeType} was used after being disposed.\n'
          '${operation != null ? ''
              'Attempted operation:\n'
              '  - $operation' '\n\n' : ''}'
          'Once dispose() has been called on a ${notifier.runtimeType}, '
          'it can no longer be used.',
        );
      }
      return true;
    }());

    return true;
  }

  /// Called whenever a [Change] occurs.
  /// A [Change] occurs before the notifier's state has been updated.
  ///
  /// This method notifies the global [NotifierObserver] that a state change
  /// is about to occur.
  ///
  /// **Note:** `super.onChange` should always be called first.
  ///
  /// ```dart
  /// @override
  /// void onChange(Change change) {
  ///   // Always call super.onChange with the current change
  ///   super.onChange(change);
  ///
  ///   // Custom onChange logic goes here
  /// }
  /// ```
  @protected
  @mustCallSuper
  void onChange(Change<State> change) {
    assert(debugAssertNotDisposed(this, 'onChange'));
    // ignore: invalid_use_of_protected_member
    _observer.onChange(this, change);
  }

  /// Called whenever an error occurs.
  /// This method notifies the global [NotifierObserver] of the error.
  ///
  /// **Note:** `super.onError` should always be called last.
  ///
  /// ```dart
  /// @override
  /// void onError(Object error, StackTrace stackTrace) {
  ///   // Custom onError logic goes here
  ///
  ///   // Always call super.onError with the current error and stackTrace
  ///   super.onError(error, stackTrace);
  /// }
  /// ```
  @protected
  @mustCallSuper
  void onError(
    Object error,
    StackTrace stackTrace,
  ) {
    assert(debugAssertNotDisposed(this, 'onError'));
    // ignore: invalid_use_of_protected_member
    _observer.onError(this, error, stackTrace);
  }

  /// disposes the instance.
  /// This method should be called when the instance is no longer needed.
  /// Before disposal, the global [NotifierObserver] is notified.
  ///
  /// This method should always call `super.dispose()`.
  @override
  @mustCallSuper
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    // ignore: invalid_use_of_protected_member
    _observer.onDispose(this);
    super.dispose();
  }
}

/// A default implementation of [NotifierObserver] that does nothing.
///
/// The [_DefaultNotifierObserver] class is used as the default observer for every notifier.
/// It provides a no-op implementation of [NotifierObserver] methods.
class _DefaultNotifierObserver extends NotifierObserver {
  const _DefaultNotifierObserver();
}
