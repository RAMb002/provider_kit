part of '../debounce.dart';

class _DebounceRouter {
  _DebounceRouter({
    required bool leading,
    required bool? trailing,
    required this._maxWait,
  }) : _leading = leading,
       _trailing = trailing ?? !leading {
    if (!_leading && !_trailing) {
      throw ArgumentError('At least one of leading or trailing must be true.');
    }

    if (_maxWait?.isNegative ?? false) {
      throw ArgumentError.value(
        _maxWait,
        'maxWait',
        'Duration cannot be negative.',
      );
    }
  }

  final bool _leading;
  final bool _trailing;
  final Duration? _maxWait;

  _DebounceImpl? _defaultDebounce;
  _DebounceGroup? _group;

  bool _disposed = false;

  _DebounceImpl _createDebounce() {
    return _DebounceImpl(
      leading: _leading,
      trailing: _trailing,
      maxWait: _maxWait,
    );
  }

  _DebounceImpl _getDefaultDebounce() {
    return _defaultDebounce ??= _createDebounce();
  }

  _DebounceGroup _getGroup() {
    return _group ??= _DebounceGroup(
      leading: _leading,
      trailing: _trailing,
      maxWait: _maxWait,
    );
  }

  void run(
    Object? key,
    void Function() operation, {
    required Duration duration,
  }) {
    assert(() {
      if (_disposed) {
        throw StateError(
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

    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration cannot be negative.',
      );
    }

    if (key == null) {
      _getDefaultDebounce().run(operation, duration: duration);
      return;
    }

    _getGroup().run(key, operation, duration: duration);
  }

  bool isPending(Object? key) {
    if (_disposed) {
      return false;
    }

    if (key == null) {
      return _defaultDebounce?.isPending ?? false;
    }

    return _group?.isPending(key) ?? false;
  }

  void cancel(Object? key) {
    if (_disposed) {
      return;
    }

    if (key == null) {
      _defaultDebounce?.cancel();
      return;
    }

    _group?.cancel(key);
  }

  void flush(Object? key) {
    if (_disposed) {
      return;
    }

    if (key == null) {
      _defaultDebounce?.flush();
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

    _defaultDebounce?.dispose();
    _group?.disposeAll();

    _defaultDebounce = null;
    _group = null;
  }
}
