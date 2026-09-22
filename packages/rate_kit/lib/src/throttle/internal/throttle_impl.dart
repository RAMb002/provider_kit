part of '../throttle.dart';

class _ThrottleImpl {
  _ThrottleImpl({
    required this._leading,
    required this._trailing,
    required this._duration,
    this._onInactive,
  });

  final bool _leading;
  final bool _trailing;
  final Duration _duration;
  final void Function()? _onInactive;

  Timer? _timer;

  void Function()? _pendingOperation;

  /// Whether a throttle period is currently active.
  bool get isThrottled => _timer != null;

  /// Whether a trailing operation is currently waiting to execute.
  bool get isTrailingPending => _pendingOperation != null;

  /// Schedules [operation] using this throttle's configuration.
  void run(void Function() operation) {
    final isNewPeriod = !isThrottled;

    if (!isNewPeriod) {
      if (_trailing) {
        // Replace the pending operation with the latest call.
        _pendingOperation = operation;
      }

      return;
    }

    // A zero duration means there is no throttle window.
    if (_duration == Duration.zero) {
      _onInactive?.call();
      operation();
      return;
    }

    // Start the throttle timer before invoking a leading operation.
    //
    // This ensures a re-entrant call from inside the operation is treated
    // as a subsequent call in the same throttle period.
    _startTimer();

    if (_leading) {
      operation();
    } else {
      _pendingOperation = operation;
    }
  }

  void _startTimer() {
    _timer = Timer(_duration, _handleTimerExpired);
  }

  void _handleTimerExpired() {
    _timer = null;

    _finishCycle();
  }

  /// Completes the current throttle period and optionally executes its
  /// trailing operation.
  void _finishCycle() {
    final operation = _pendingOperation;

    _pendingOperation = null;

    if (_trailing && operation != null) {
      // Start the next throttle period before invoking the trailing
      // operation so re-entrant calls remain throttled.
      _startTimer();

      operation();

      return;
    }

    _onInactive?.call();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels the current throttle period.
  void cancel() {
    _stopTimer();
    _pendingOperation = null;
    _onInactive?.call();
  }

  /// Immediately executes the pending trailing operation.
  ///
  /// A new throttle period starts from the time [flush] is called.
  void flush() {
    if (!isThrottled) {
      return;
    }

    if (!_trailing || _pendingOperation == null) {
      return;
    }

    _stopTimer();
    _finishCycle();
  }

  /// Disposes this throttle implementation permanently.
  void dispose() {
    _stopTimer();
    _pendingOperation = null;
  }
}
