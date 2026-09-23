part of '../throttle.dart';

class _ThrottleGroup {
  _ThrottleGroup({
    required this._leading,
    required this._trailing,
    required this._duration,
  });

  final bool _leading;
  final bool _trailing;
  final Duration _duration;

  final Map<Object, _ThrottleImpl> _throttles = {};

  _ThrottleImpl _createThrottle(Object key) {
    return _ThrottleImpl(
      leading: _leading,
      trailing: _trailing,
      duration: _duration,
      onInactive: () {
        _throttles.remove(key);
      },
    );
  }

  _ThrottleImpl _getOrCreate(Object key) {
    return _throttles.putIfAbsent(key, () => _createThrottle(key));
  }

  _ThrottleImpl? _get(Object key) {
    return _throttles[key];
  }

  void run(Object key, void Function() operation) {
    _getOrCreate(key).run(operation);
  }

  bool isThrottled(Object key) {
    return _get(key)?.isThrottled ?? false;
  }

  bool isTrailingPending(Object key) {
    return _get(key)?.isTrailingPending ?? false;
  }

  void cancel(Object key) {
    _get(key)?.cancel();
  }

  void flush(Object key) {
    _get(key)?.flush();
  }

  void disposeKey(Object key) {
    final throttle = _throttles.remove(key);

    throttle?.dispose();
  }

  void disposeAll() {
    for (final throttle in _throttles.values) {
      throttle.dispose();
    }

    _throttles.clear();
  }
}
