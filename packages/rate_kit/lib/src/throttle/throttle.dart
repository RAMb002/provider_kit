import 'dart:async';

import '../constants.dart';

part 'internal/throttle_group.dart';
part 'internal/throttle_impl.dart';
part 'internal/throttle_router.dart';

/// {@template rate_kit.throttle}
/// Limits how frequently an operation can be executed.
///
/// A throttle divides calls into fixed time windows. Once a window starts,
/// new calls do not extend it.
///
/// By default, the first operation in a window executes immediately, and
/// further calls are ignored until the window ends.
///
/// This is useful for operations that may be triggered repeatedly in a short
/// period, such as button taps, scrolling, pointer movement, analytics, and
/// other high-frequency events.
///
/// ### Basic usage
///
/// ```dart
/// final throttle = Throttle(
///   duration: const Duration(milliseconds: 300),
/// );
///
/// throttle.run(() {
///   sendAnalytics();
/// });
/// ```
///
/// The default duration is 300 milliseconds.
///
/// During the active throttle period, further calls do not restart the timer:
///
/// ```dart
/// throttle.run(() => sendAnalytics());
/// throttle.run(() => sendAnalytics());
/// throttle.run(() => sendAnalytics());
/// ```
///
/// The first operation runs immediately, while the following calls are
/// ignored until the 300-millisecond period ends.
///
/// ### Leading and trailing
///
/// A throttle can execute an operation at the leading edge, the trailing
/// edge, or both.
///
/// #### Leading
///
/// By default, [Throttle] uses leading execution.
///
/// ```dart
/// final throttle = Throttle();
/// ```
///
/// ```text
/// Time →   0ms      100ms     200ms     300ms     400ms     500ms     600ms
///           │         │         │         │         │         │         │
/// Calls →   ●         ●         ●         ●         ●         ●         ●
///           ↓         ×         ×         ↓         ×         ×         ↓
///          RUN     ignored   ignored     RUN     ignored   ignored     RUN
///           │─────────────────────────────│─────────────────────────────│
///                         300ms                         300ms
/// ```
///
/// The first operation runs immediately. Further calls during the same
/// throttle period are ignored. The timer does not restart when new calls
/// arrive.
///
/// #### Trailing
///
/// ```dart
/// final throttle = Throttle(
///   trailing: true,
/// );
/// ```
///
/// ```text
/// Time →   0ms      100ms     200ms      300ms      400ms     500ms      600ms
///           │         │         │          │          │         │          │
/// Calls →   ●         ●         ●          ●          ●         ●          ●
///           │         │         │          ↓          │         │          ↓
///         pending  replace    replace   RUN latest  replace    replace   RUN latest
///                  pending    pending               pending    pending
///           │──────────────────────────────│───────────────────────────────│
///                         300ms                         300ms
/// ```
///
/// With trailing execution, the latest operation received during the throttle
/// period replaces the pending operation and is executed when the period ends.
///
/// When [trailing] is `true` and [leading] is not configured, leading
/// execution defaults to `false`.
///
/// #### Leading + trailing
///
/// ```dart
/// final throttle = Throttle(
///   leading: true,
///   trailing: true,
/// );
/// ```
///
/// ```text
/// Time →   0ms      100ms     200ms      300ms      400ms     500ms      600ms
///           │         │         │          │          │         │          │
/// Calls →   ●         ●         ●          ●          ●         ●          ●
///           │         │         │          ↓          │         │          ↓
///         RUN      replace    replace   RUN latest  replace    replace   RUN latest
///                  pending    pending               pending    pending
///           │──────────────────────────────│───────────────────────────────│
///                         300ms                         300ms
/// ```
///
/// The first operation runs immediately. If another call occurs during the
/// throttle period, the latest operation runs when the period ends.
///
/// After a trailing operation executes, another throttle period starts.
/// This keeps at least [duration] between consecutive executions.
///
/// ### Duration
///
/// [duration] defaults to 300 milliseconds.
///
/// The duration is fixed for each throttle period. Calls made while the
/// throttle period is active cannot change its duration.
///
/// A duration of [Duration.zero] executes the operation immediately without
/// creating a throttle period.
///
/// ### Status
///
/// Use [isThrottled] to check whether a throttle period is currently active.
///
/// Use [isTrailingPending] to check whether a trailing operation is waiting
/// to execute.
///
/// ### Cancel
///
/// Use [cancel] to end the current throttle period and discard any pending
/// trailing operation.
///
/// The [Throttle] can be reused after cancellation.
///
/// ### Flush
///
/// Use [flush] to immediately execute a pending trailing operation.
///
/// When a trailing operation is flushed, a new throttle period starts from
/// the time [flush] is called. This preserves the minimum duration between
/// executions.
///
/// If trailing execution is disabled or no operation is pending, [flush]
/// does nothing.
///
/// ```dart
/// throttle.flush();
/// ```
///
/// ### Dispose
///
/// Use [dispose] when the [Throttle] is no longer needed.
///
/// ```dart
/// throttle.dispose();
/// ```
///
/// Once the entire [Throttle] has been disposed, it should not be used again.
/// Calling [dispose] more than once is safe.
///
/// ### Keys
///
/// A [Throttle] can manage multiple independent operations using keys.
///
/// ```dart
/// final throttle = Throttle();
///
/// throttle.run(
///   sendAnalytics,
///   key: 'analytics',
/// );
///
/// throttle.run(
///   updateCursor,
///   key: 'cursor',
/// );
/// ```
///
/// Each key has its own independent throttle, so calls made with one key do
/// not affect another.
///
/// ```dart
/// throttle.isThrottled(key: 'analytics');
///
/// throttle.cancel(key: 'analytics');
///
/// throttle.flush(key: 'cursor');
/// ```
///
/// Dispose a specific keyed throttle:
///
/// ```dart
/// throttle.dispose(key: 'analytics');
/// ```
///
/// Providing a key to [dispose] disposes only that keyed throttle while the
/// [Throttle] instance remains usable.
///
/// Calling [dispose] without a key disposes the entire instance, including
/// all keyed throttles it manages.
///
/// ### Errors
///
/// An [ArgumentError] is thrown when [duration] is negative, or when both
/// [leading] and [trailing] resolve to `false`.
///
/// {@endtemplate}
class Throttle {
  /// {@macro rate_kit.throttle}
  Throttle({
    Duration duration = defaultRateDuration,
    bool? leading,
    bool trailing = false,
  }) : _router = _ThrottleRouter(
         leading: leading,
         trailing: trailing,
         duration: duration,
       ) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration cannot be negative.',
      );
    }
  }

  final _ThrottleRouter _router;

  /// Schedules [operation] for execution.
  ///
  /// When the throttle is active, additional calls are ignored unless
  /// trailing execution is enabled, in which case the latest operation
  /// replaces the pending trailing operation.
  ///
  /// When [key] is provided, the operation uses that key's independent
  /// throttle.
  void run(void Function() operation, {Object? key}) {
    _router.run(key, operation);
  }

  /// Whether this throttle currently has an active throttle period.
  ///
  /// While throttled, another operation cannot execute immediately.
  bool isThrottled({Object? key}) {
    return _router.isThrottled(key);
  }

  /// Whether a trailing operation is currently waiting to execute.
  ///
  /// Returns `true` when trailing execution is enabled and an operation
  /// is pending for the current throttle period.
  ///
  /// Returns `false` when there is no pending trailing operation.
  bool isTrailingPending({Object? key}) {
    return _router.isTrailingPending(key);
  }

  /// Cancels the current throttle period without executing its pending
  /// trailing operation.
  ///
  /// When [key] is provided, only that key's throttle is cancelled.
  ///
  /// The throttle can be reused after cancellation.
  void cancel({Object? key}) {
    _router.cancel(key);
  }

  /// Immediately executes a pending trailing operation.
  ///
  /// When a trailing operation is flushed, a new throttle period starts from
  /// the time [flush] is called.
  ///
  /// When [key] is provided, only that key's throttle is flushed.
  ///
  /// Calling [flush] when trailing execution is disabled or no operation is
  /// pending does nothing.
  void flush({Object? key}) {
    _router.flush(key);
  }

  /// Disposes the [Throttle].
  ///
  /// When using keyed throttles, pass a [key] to dispose only that throttle:
  ///
  /// ```dart
  /// throttle.dispose(key: 'analytics');
  /// ```
  ///
  /// Calling [dispose] without a key disposes the entire instance, including
  /// all keyed throttles.
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
