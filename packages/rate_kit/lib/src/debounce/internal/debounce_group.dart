part of '../debounce.dart';

class _DebounceGroup {
  _DebounceGroup({
    required this._leading,
    required this._trailing,
    required this._maxWait,
  });

  final bool _leading;
  final bool _trailing;
  final Duration? _maxWait;

  final Map<Object, _DebounceImpl> _debounces = {};

  _DebounceImpl _createDebounce(Object key) {
    return _DebounceImpl(
      leading: _leading,
      trailing: _trailing,
      maxWait: _maxWait,
      onComplete: () {
        _debounces.remove(key);
      },
    );
  }

  _DebounceImpl _getOrCreate(Object key) {
    return _debounces.putIfAbsent(key, () => _createDebounce(key));
  }

  _DebounceImpl? _get(Object key) {
    return _debounces[key];
  }

  void run(
    Object key,
    void Function() operation, {
    required Duration duration,
  }) {
    _getOrCreate(key).run(operation, duration: duration);
  }

  bool isPending(Object key) {
    return _get(key)?.isPending ?? false;
  }

  void cancel(Object key) {
    _get(key)?.cancel();
  }

  void flush(Object key) {
    _get(key)?.flush();
  }

  void disposeKey(Object key) {
    final debounce = _debounces.remove(key);

    debounce?.dispose();
  }

  void disposeAll() {
    for (final debounce in _debounces.values) {
      debounce.dispose();
    }

    _debounces.clear();
  }
}
