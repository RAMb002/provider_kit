part of 'debounce.dart';

/// {@template provider_kit.debounce_key}
/// Provides globally keyed debounce operations.
///
/// Calls using the same [key] use the same debounce operation. Calling [run]
/// again with the same key replaces any pending operation and starts the
/// debounce delay again.
///
/// Different keys use independent debounce operations.
///
/// The default duration is 300 milliseconds.
///
/// ```dart
/// DebounceKey.run(
///   'search',
///   () {
///     searchUsers();
///   },
/// );
///
/// DebounceKey.run(
///   'movies',
///   () {
///     searchMovies();
///   },
/// );
///
/// // Cancels the pending operation.
/// DebounceKey.cancel('search');
///
/// // Dispose when the keyed debounce is no longer needed.
/// DebounceKey.dispose('search');
/// ```
///
/// {@endtemplate}
class DebounceKey {
  DebounceKey._();

  static final _DebounceRegistry _registry = _DebounceRegistry();

  /// Runs a globally keyed debounce.
  ///
  /// Calls using the same [key] use the same debounce operation. Calling [run]
  /// again with the same key replaces any pending operation and starts the
  /// debounce delay again.
  ///
  /// If the [duration] changes, the debounce for that key uses the new
  /// duration.
  ///
  /// Example:
  /// ```dart
  /// DebounceKey.run(
  ///   'user-search',
  ///   () {
  ///     searchUsers();
  ///   },
  /// );
  /// ```
  ///
  /// The default duration is 300 milliseconds.
  static void run(
    Object key,
    void Function() operation, {
    Duration duration = _defaultDuration,
  }) {
    _registry.run(
      key,
      operation,
      duration: duration,
    );
  }

  /// Cancels the pending operation associated with [key].
  ///
  /// The keyed debounce remains active and can be used again with [run].
  static void cancel(Object key) {
    _registry.cancel(key);
  }

  /// Disposes the debounce associated with [key].
  ///
  /// Any pending operation for the key will not be executed.
  static void dispose(Object key) {
    _registry.dispose(key);
  }

  /// Disposes all globally keyed debounce operations.
  ///
  /// Any pending operations will not be executed.
  static void disposeAll() {
    _registry.disposeAll();
  }
}
