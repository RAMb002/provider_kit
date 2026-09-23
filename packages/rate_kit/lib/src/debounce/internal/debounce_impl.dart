part of '../debounce.dart';

class _DebounceImpl {
  _DebounceImpl({
    required this._leading,
    required this._trailing,
    required this._maxWait,
    this._onComplete,
  });

  final bool _leading;
  final bool _trailing;
  final Duration? _maxWait;
  final void Function()? _onComplete;

  Timer? _timer;
  Timer? _maxWaitTimer;

  void Function()? _pendingOperation;

  bool _hasAdditionalCall = false;

  /// Whether a debounce cycle is currently active.
  bool get isPending => _timer != null;

  /// Schedules [operation] using this debounce's configuration.
  void run(void Function() operation, {required Duration duration}) {
    final isNewCycle = !isPending;

    _pendingOperation = operation;

    if (isNewCycle) {
      _hasAdditionalCall = false;

      // Start the timers before invoking a leading operation.
      //
      // This ensures a re-entrant call from inside the operation is treated
      // as a subsequent call in the same debounce cycle.
      _startDebounceTimer(duration);
      _startMaxWaitTimer();

      if (_leading) {
        _invokeLeading();
      }

      return;
    }

    // Another call arrived while the debounce cycle is active.
    _hasAdditionalCall = true;

    // New calls restart the normal debounce timer.
    // The maxWait timer intentionally does not restart.
    _startDebounceTimer(duration);
  }

  void _startDebounceTimer(Duration duration) {
    _timer?.cancel();

    _timer = Timer(duration, _handleDebounceExpired);
  }

  void _startMaxWaitTimer() {
    final maxWait = _maxWait;

    if (maxWait == null) {
      return;
    }

    _maxWaitTimer = Timer(maxWait, _handleMaxWaitExpired);
  }

  void _handleDebounceExpired() {
    _timer = null;

    _finishCycle();
  }

  void _handleMaxWaitExpired() {
    _maxWaitTimer = null;

    _finishCycle();
  }

  /// Completes the current debounce cycle and optionally executes its
  /// trailing operation.
  void _finishCycle() {
    final operation = _pendingOperation;

    final shouldInvokeTrailing =
        _trailing && operation != null && (!_leading || _hasAdditionalCall);

    _stopTimers();

    _pendingOperation = null;
    _hasAdditionalCall = false;

    _onComplete?.call();

    if (shouldInvokeTrailing) {
      operation();
    }
  }

  /// Executes the pending operation for the leading edge.
  ///
  /// The pending operation is cleared before invocation so that a re-entrant
  /// call can safely register a new pending operation.
  void _invokeLeading() {
    final operation = _pendingOperation;

    _pendingOperation = null;

    operation?.call();
  }

  void _stopTimers() {
    _timer?.cancel();
    _maxWaitTimer?.cancel();

    _timer = null;
    _maxWaitTimer = null;
  }

  /// Cancels the current debounce cycle.
  void cancel() {
    _stopTimers();

    _pendingOperation = null;
    _hasAdditionalCall = false;

    _onComplete?.call();
  }

  /// Immediately completes the current debounce cycle.
  ///
  /// Only a pending trailing operation is executed.
  void flush() {
    if (!isPending) {
      return;
    }
    _finishCycle();
  }

  /// Disposes this debounce implementation permanently.
  void dispose() {
    _stopTimers();

    _pendingOperation = null;
    _hasAdditionalCall = false;
  }
}
