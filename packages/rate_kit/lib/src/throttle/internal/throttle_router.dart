part of '../throttle.dart';

class _ThrottleRouter {
  _ThrottleRouter({
    required bool? leading,
    required bool trailing,
    required this._duration,
  }) : _leading = leading ?? !trailing,
       _trailing = trailing {
    if (!_leading && !_trailing) {
      throw ArgumentError('At least one of leading or trailing must be true.');
    }
  }

  final bool _leading;
  final bool _trailing;
  final Duration _duration;

  _ThrottleImpl? _defaultThrottle;
  _ThrottleGroup? _group;

  bool _disposed = false;

  _ThrottleImpl _createThrottle() {
    return _ThrottleImpl(
      leading: _leading,
      trailing: _trailing,
      duration: _duration,
    );
  }

  _ThrottleImpl _getDefaultThrottle() {
    return _defaultThrottle ??= _createThrottle();
  }

  _ThrottleGroup _getGroup() {
    return _group ??= _ThrottleGroup(
      leading: _leading,
      trailing: _trailing,
      duration: _duration,
    );
  }

  void run(Object? key, void Function() operation) {
    assert(() {
      if (_disposed) {
        throw StateError(
          'A Throttle was used after being disposed.\n'
          'Once you have called dispose() on a Throttle, it can no longer '
          'be used.',
        );
      }

      return true;
    }());

    if (_disposed) {
      return;
    }

    if (key == null) {
      _getDefaultThrottle().run(operation);
      return;
    }

    _getGroup().run(key, operation);
  }

  bool isThrottled(Object? key) {
    if (_disposed) return false;
    if (key == null) return _defaultThrottle?.isThrottled ?? false;
    return _group?.isThrottled(key) ?? false;
  }

  bool isTrailingPending(Object? key) {
    if (_disposed) return false;
    if (key == null) return _defaultThrottle?.isTrailingPending ?? false;
    return _group?.isTrailingPending(key) ?? false;
  }

  void cancel(Object? key) {
    if (_disposed) {
      return;
    }
    if (key == null) {
      _defaultThrottle?.cancel();
      return;
    }
    _group?.cancel(key);
  }

  void flush(Object? key) {
    if (_disposed) {
      return;
    }
    if (key == null) {
      _defaultThrottle?.flush();
      return;
    }
    _group?.flush(key);
  }

  void disposeKey(Object key) {
    if (_disposed) {
      return;
    }
    _group?.disposeKey(key);
  }

  void disposeAll() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _defaultThrottle?.dispose();
    _group?.disposeAll();

    _defaultThrottle = null;
    _group = null;
  }
}
