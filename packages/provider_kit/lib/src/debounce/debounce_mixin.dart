part of 'debounce.dart';

/// Provides debounce support for a [ChangeNotifier].
///
/// Debounces created through [debounce] are automatically disposed when the
/// notifier is disposed.
///
/// ```dart
/// class SearchController extends ChangeNotifier with DebounceMixin {
///   void search(String query) {
///     debounce(
///       () {
///         performSearch(query);
///       },
///     );
///   }
/// }
/// ```
///
/// Multiple debounce operations can be managed using different keys:
///
/// ```dart
/// debounceKey(
///   'users',
///   () => searchUsers(),
/// );
///
/// debounceKey(
///   'movies',
///   () => searchMovies(),
/// );
/// ```
///
/// Individual debounce operations can also be cancelled or disposed manually.
mixin DebounceMixin on ChangeNotifier {
  final _DebounceRegistry _debounceRegistry = _DebounceRegistry();

  /// Schedules [operation] using the default debounce.
  ///
  /// Calling this again before the duration has passed replaces any pending
  /// operation and starts the debounce delay again.
  ///
  /// The default duration is 300 milliseconds.
  void debounce(
    void Function() operation, {
    Duration duration = _defaultDuration,
  }) {
    _debounceRegistry.run(
      _defaultDebounceKey,
      operation,
      duration: duration,
    );
  }

  /// Schedules [operation] using the debounce associated with [key].
  ///
  /// Calling this again with the same [key] replaces any pending operation and
  /// starts the debounce delay again.
  ///
  /// The default duration is 300 milliseconds.
  void debounceKey(
    Object key,
    void Function() operation, {
    Duration duration = _defaultDuration,
  }) {
    _debounceRegistry.run(
      key,
      operation,
      duration: duration,
    );
  }

  /// Cancels the pending operation for the default debounce.
  ///
  /// The debounce remains active and can be used again with [debounce].
  void cancelDebounce() {
    _debounceRegistry.cancel(_defaultDebounceKey);
  }

  /// Cancels the pending operation associated with [key].
  ///
  /// The keyed debounce remains active and can be used again with
  /// [debounceKey].
  void cancelDebounceKey(Object key) {
    _debounceRegistry.cancel(key);
  }

  /// Disposes the default debounce.
  ///
  /// Any pending operation will not be executed.
  void disposeDebounce() {
    _debounceRegistry.dispose(_defaultDebounceKey);
  }

  /// Disposes the debounce associated with [key].
  ///
  /// Any pending operation for the key will not be executed.
  void disposeDebounceKey(Object key) {
    _debounceRegistry.dispose(key);
  }

  @override
  void dispose() {
    _debounceRegistry.disposeAll();
    super.dispose();
  }
}

class _DefaultDebounceKey {
  const _DefaultDebounceKey();
}

const Object _defaultDebounceKey = _DefaultDebounceKey();
