part of '../core/provider_kit_core.dart';

/// The foundation for all notifiers in this package.
///
/// [NotifierBase] centralises lifecycle and observer behaviour shared by every
/// notifier implementation – including state change notification, error
/// reporting, disposal, and Flutter memory allocation tracking.
///
/// This class is an internal foundation for ProviderKit notifiers and is not
/// intended to be used directly by application code.
///
/// Instead of extending [NotifierBase], you should extend one of the concrete
/// notifier implementations provided by this package, such as:
///
/// - [StateNotifier] – for simple value state management.
/// - [FutureNotifier] – for asynchronous view‑state fetching.
///
/// ### Observing notifier lifecycle events
///
/// To observe notifier lifecycle events globally, configure a
/// [NotifierObserver] through [ProviderKit.configure]:
///
/// ```dart
/// ProviderKit.configure(
///   observer: MyNotifierObserver(),
/// );
/// ```
///
/// The observer receives `onChange`, `onError`, and `onDispose` events for
/// every live notifier. `onCreate` is delivered only for notifiers created
/// after the observer is configured.
///
/// ### Overriding hooks
///
/// [onChange] and [onError] are optional hooks for subclasses:
///
/// - [onChange] runs before the state is updated.
/// - [onError] runs when the notifier reports an error.
///
/// Exceptions thrown from a hook are reported to Flutter through
/// [FlutterError.reportError]. They never prevent the state update, and they
/// never prevent the observer from being notified.
///
/// ### Subclassing guidelines
///
/// When creating a custom notifier:
///
/// - Override [onChange] or [onError] to add custom behavior.
/// - Call `super` in an override when needed to preserve behavior from
///   an intermediate superclass.
/// - Call `super.dispose()` in an override of [dispose].
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
    _notifyObserver('onCreate', () => _observer.onCreate(this));

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
  static bool debugAssertNotDisposed(
    NotifierBase<dynamic> notifier, [
    String? operation,
  ]) {
    assert(() {
      if (notifier._disposed) {
        throw FlutterError(
          '\n'
          'A ${notifier.runtimeType} was used after being disposed.\n'
          '${operation != null ? ''
                    'Attempted operation:\n'
                    '  - $operation'
                    '\n\n' : ''}'
          'Once dispose() has been called on a ${notifier.runtimeType}, '
          'it can no longer be used.',
        );
      }
      return true;
    }());

    return true;
  }

  /// A hook called before the notifier's state is updated.
  ///
  /// Override this to run logic when a [Change] is about to occur, such as
  /// logging or analytics. [Change.currentState] is the state before the
  /// update and [Change.nextState] is the state about to be applied.
  ///
  /// The default implementation does nothing.
  ///
  /// Exceptions thrown here are reported to Flutter. They do not prevent the
  /// state update or the observer notification, so this hook can observe a
  /// change but cannot cancel it.
  ///
  /// Avoid assigning state from inside this hook. It re-enters the state
  /// setter while a change is already in progress.
  ///
  /// Framework code should call [dispatchChange] instead of calling this
  /// method directly.
  ///
  /// ```dart
  /// @override
  /// void onChange(Change<int> change) {
  ///   debugPrint('${change.currentState} -> ${change.nextState}');
  /// }
  /// ```
  @protected
  void onChange(Change<State> change) {}

  /// Runs the [onChange] hook, then notifies the global [NotifierObserver].
  ///
  /// Exceptions thrown by the hook are reported to Flutter. If the hook
  /// disposes the notifier, observer notification is skipped.
  @protected
  @nonVirtual
  void dispatchChange(Change<State> change) {
    assert(debugAssertNotDisposed(this, 'dispatchChange'));

    try {
      onChange(change);
    } catch (error, stackTrace) {
      _reportToFlutter(
        error,
        stackTrace,
        'While running onChange of $runtimeType',
      );
    }

    if (!mounted) return;

    _notifyObserver(
      'onChange',
      // ignore: invalid_use_of_protected_member
      () => _observer.onChange(this, change),
    );
  }

  /// A hook called when this notifier reports an error.
  ///
  /// Override this to react to errors, such as logging them. The default
  /// implementation does nothing.
  ///
  /// Exceptions thrown here are reported to Flutter. They do not replace the
  /// original [error] and do not prevent the observer notification.
  ///
  /// Framework code should call [dispatchError] instead of calling this
  /// method directly.
  ///
  /// ```dart
  /// @override
  /// void onError(Object error, StackTrace stackTrace) {
  ///   debugPrint('Notifier failed: $error');
  /// }
  /// ```
  @protected
  void onError(Object error, StackTrace stackTrace) {}

  /// Runs the [onError] hook, then notifies the global [NotifierObserver].
  ///
  /// Exceptions thrown by the hook are reported to Flutter without replacing
  /// the original error. If the hook disposes the notifier, observer
  /// notification is skipped.
  @protected
  @nonVirtual
  void dispatchError(Object error, StackTrace stackTrace) {
    assert(debugAssertNotDisposed(this, 'dispatchError'));

    if (!mounted) return;

    try {
      onError(error, stackTrace);
    } catch (hookError, hookStackTrace) {
      _reportToFlutter(
        hookError,
        hookStackTrace,
        'While running onError of $runtimeType',
      );
    }

    if (!mounted) return;

    _notifyObserver(
      'onError',
      // ignore: invalid_use_of_protected_member
      () => _observer.onError(this, error, stackTrace),
    );
  }

  /// Notifies the global [NotifierObserver] of an error without invoking
  /// the overridable [onError] hook.
  ///
  /// Does nothing if the notifier has been disposed.
  @protected
  @nonVirtual
  void dispatchErrorToObserver(Object error, StackTrace stackTrace) {
    assert(debugAssertNotDisposed(this, 'dispatchErrorToObserver'));

    if (!mounted) return;

    _notifyObserver(
      'onError',
      // ignore: invalid_use_of_protected_member
      () => _observer.onError(this, error, stackTrace),
    );
  }

  /// Calls the observer, reporting any exception it throws to Flutter instead
  /// of letting it break notifier behavior.
  void _notifyObserver(String event, void Function() call) {
    try {
      call();
    } catch (error, stackTrace) {
      _reportToFlutter(
        error,
        stackTrace,
        'While notifying the observer of $event',
      );
    }
  }

  void _reportToFlutter(Object error, StackTrace stackTrace, String message) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'provider_kit',
        context: ErrorDescription(message),
      ),
    );
  }

  /// Disposes this notifier.
  ///
  /// Call this when the notifier is no longer needed. The global
  /// [NotifierObserver] is notified before the underlying [ChangeNotifier] is
  /// disposed. Calling it more than once has no effect.
  ///
  /// Subclasses overriding this method must call `super.dispose()`.
  @override
  @mustCallSuper
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    // ignore: invalid_use_of_protected_member
    _notifyObserver('onDispose', () => _observer.onDispose(this));
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
