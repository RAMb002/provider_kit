part of '../debounce.dart';

/// Internal implementation of a debounce operation.
class _DebounceImpl {
  Timer? _timer;
  bool _disposed = false;

  /// Whether an operation is currently waiting to be executed.
  bool get isPending => _timer?.isActive ?? false;

  /// Schedules [operation] to run after [duration].
  /// Replaces any pending operation and restarts the debounce delay.
  /// Throws in debug mode if this debounce has been disposed.
  void run(
    void Function() operation, {
    required Duration duration,
  }) {
    assert(() {
      if (_disposed) {
        throw FlutterError(
          'A Debounce was used after being disposed.\n'
          'Once you have called dispose() on a Debounce, it can no longer '
          'be used.',
        );
      }

      return true;
    }());

    if (_disposed) {
      return;
    }

    _timer?.cancel();

    _timer = Timer(
      duration,
      () {
        _timer = null;

        if (_disposed) {
          return;
        }

        operation();
      },
    );
  }

  /// Cancels the pending operation.
  ///
  /// This debounce remains active and can be used again.
  void cancel() {
    if (_disposed) {
      return;
    }

    _timer?.cancel();
    _timer = null;
  }

  /// Disposes this debounce and cancels any pending operation.
  ///
  /// A disposed debounce cannot be used again.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _timer?.cancel();
    _timer = null;
  }
}
