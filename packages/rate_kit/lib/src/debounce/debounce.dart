import 'dart:async';

import '../constants.dart';

part 'internal/debounce_group.dart';
part 'internal/debounce_impl.dart';
part 'internal/debounce_router.dart';

/// {@template rate_kit.debounce}
/// Delays an operation until calls have stopped for the configured
/// [duration].
///
/// Each new call resets the debounce timer and replaces the previously
/// pending operation. Once no new calls occur within the duration, the latest
/// operation is executed.
///
/// This is useful for operations that may be triggered repeatedly in a short
/// period, such as search, input validation, filtering, autosave, and API
/// requests.
///
/// ### Basic usage
///
/// ```dart
/// final debounce = Debounce(
///   duration: const Duration(milliseconds: 300),
/// );
///
/// debounce.run(() {
///   search(query);
/// });
/// ```
///
/// Calling [run] again before the duration expires replaces the previous
/// operation and restarts the timer.
///
/// ```dart
/// debounce.run(() => search('f'));
/// debounce.run(() => search('fl'));
/// debounce.run(() => search('flu'));
/// debounce.run(() => search('flut'));
/// debounce.run(() => search('flutt'));
/// debounce.run(() => search('flutte'));
/// debounce.run(() => search('flutter'));
/// ```
///
/// Because no new call occurs for 300 milliseconds after the last call,
/// `search('flutter')` is executed after 300 milliseconds.
///
/// ### Leading and trailing
///
/// A debounce can execute an operation at the leading edge, the trailing
/// edge, or both.
///
/// #### Trailing
///
/// ```dart
/// final debounce = Debounce();
/// ```
///
/// ```text
/// User types:     f   l   u   t   t   e   r
///                                             ↑
///                                             │
///                                             └── runs "flutter"
/// ```
///
/// By default, [Debounce] uses trailing execution. The latest operation runs
/// after calls have stopped for the configured duration.
///
/// #### Leading
///
/// ```dart
/// final debounce = Debounce(
///   leading: true,
/// );
/// ```
///
/// ```text
/// User types:     f   l   u   t   t   e   r
///                 ↑
///                 │
///                 └── runs immediately
/// ```
///
/// Leading execution runs the first operation immediately when a new
/// debounce cycle begins. Further calls during the same cycle do not run
/// immediately.
///
/// When [leading] is `true` and [trailing] is not configured, trailing
/// execution defaults to `false`.
///
/// #### Leading + trailing
///
/// ```dart
/// final debounce = Debounce(
///   leading: true,
///   trailing: true,
/// );
/// ```
///
/// ```text
/// User types:     f   l   u   t   t   e   r
///                 ↑                           ↑
///                 │                           │
///              runs "f"                runs "flutter"
/// ```
///
/// The first operation runs immediately, and the latest operation runs again
/// after calls have stopped. The trailing operation runs only when another
/// call occurred during the active cycle.
///
/// ### Maximum wait
///
/// [maxWait] sets an upper limit on how long a debounce cycle can remain
/// active.
///
/// ```dart
/// final debounce = Debounce(
///   duration: const Duration(milliseconds: 300),
///   maxWait: const Duration(seconds: 2),
/// );
/// ```
///
/// Imagine the user keeps typing without stopping.
///
/// ```text
/// User types:   f   l   u   t   t   e   r   ...
///               |---|---|---|---|---|---|
///                 new calls keep resetting the 300ms timer
///
/// Without maxWait:
///               keeps waiting...
///
/// With maxWait = 2 seconds:
///                2s
///                ↓
///        latest operation runs
/// ```
///
/// Normally, the debounce keeps waiting as long as new calls keep arriving.
/// [maxWait] puts a limit on that waiting time.
///
/// When trailing execution is enabled and another call occurred during the
/// cycle, reaching [maxWait] executes the latest operation and ends the cycle.
///
/// When only leading execution is enabled, the first operation has already
/// executed, so reaching [maxWait] simply ends the active cycle.
///
/// ### Duration
///
/// [duration] defaults to 300 milliseconds.
///
/// A different duration can be provided for an individual call:
///
/// ```dart
/// debounce.run(
///   () => search(query),
///   duration: const Duration(milliseconds: 500),
/// );
/// ```
///
/// ### Pending
///
/// Use [isPending] to check whether a debounce cycle is active.
///
/// A cycle may remain active even when no operation is waiting to execute,
/// such as after the leading operation of a leading-only debounce.
///
/// ### Cancel
///
/// Use [cancel] to discard the current cycle without executing its pending
/// operation. The [Debounce] can be reused after cancellation.
///
/// ### Flush
///
/// Use [flush] to immediately finish the current cycle. If trailing execution
/// is enabled and an operation is pending, it is executed immediately.
/// Calling [flush] when no cycle is active does nothing.
///
/// ```dart
/// debounce.flush();
/// ```
///
/// ### Dispose
///
/// Use [dispose] when the [Debounce] is no longer needed.
///
/// ```dart
/// debounce.dispose();
/// ```
///
/// Once the entire [Debounce] has been disposed, it should not be used again.
/// Calling [dispose] more than once is safe.
///
/// ### Keys
///
/// A [Debounce] can be used normally without a key, or a single instance can
/// manage multiple independent debounce cycles by providing a [key].
///
/// ```dart
/// debounce.run(
///   () => searchUsers(query),
///   key: 'users',
/// );
///
/// debounce.run(
///   () => searchMovies(query),
///   key: 'movies',
/// );
/// ```
///
/// Each key has its own independent debounce cycle and does not affect other
/// keys.
///
/// [isPending], [cancel], [flush], and [dispose] can also be used with a key
/// to control that specific cycle.
///
/// ```dart
/// debounce.dispose(key: 'users');
/// ```
///
/// Providing a key to [dispose] disposes only that keyed debounce while the
/// [Debounce] instance remains usable.
///
/// Calling [dispose] without a key
/// disposes the entire instance, including all keyed debounces it manages.
///
/// {@endtemplate}
class Debounce {
  /// {@macro rate_kit.debounce}
  Debounce({
    Duration duration = defaultRateDuration,
    bool leading = false,
    bool? trailing,
    Duration? maxWait,
  }) : _duration = duration,
       _router = _DebounceRouter(
         leading: leading,
         trailing: trailing,
         maxWait: maxWait,
       ) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration cannot be negative.',
      );
    }
  }

  final _DebounceRouter _router;
  final Duration _duration;

  /// Schedules [operation] for execution.
  ///
  /// Calling [run] again before the debounce duration expires replaces the
  /// pending operation and restarts the timer.
  ///
  /// When [key] is provided, the operation uses that key's independent
  /// debounce cycle.
  ///
  /// When [duration] is omitted, the duration configured for this [Debounce]
  /// instance is used.
  void run(void Function() operation, {Object? key, Duration? duration}) {
    _router.run(key, operation, duration: duration ?? _duration);
  }

  /// Whether a debounce cycle is currently active.
  ///
  /// A cycle may remain active even when no operation is waiting to execute,
  /// such as after the leading operation of a leading-only debounce.
  ///
  /// When [key] is provided, checks that key's debounce cycle.
  bool isPending({Object? key}) {
    return _router.isPending(key);
  }

  /// Cancels the current debounce cycle without executing its pending
  /// operation.
  ///
  /// When [key] is provided, only that key's debounce cycle is cancelled.
  ///
  /// The debounce can be reused after cancellation.
  void cancel({Object? key}) {
    _router.cancel(key);
  }

  /// Immediately finishes the current debounce cycle.
  ///
  /// If trailing execution is enabled and an operation is pending, it is
  /// executed immediately.
  ///
  /// When [key] is provided, only that key's debounce cycle is flushed.
  /// Calling [flush] when no cycle is active does nothing.
  void flush({Object? key}) {
    _router.flush(key);
  }

  /// Disposes the [Debounce].
  ///
  /// When using keyed debounces, pass a [key] to dispose only that debounce:
  ///
  /// ```dart
  /// debounce.dispose(key: 'users');
  /// ```
  ///
  /// Calling [dispose] without a key disposes the entire instance, including
  /// all keyed debounces.
  ///
  /// Calling [dispose] more than once is safe.
  void dispose({Object? key}) {
    if (key != null) {
      _router.disposeKey(key);
      return;
    }

    _router.disposeAll();
  }
}
