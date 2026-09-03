part of '../debounce.dart';

/// Internal registry for keyed debounce operations.
class _DebounceRegistry {
  final Map<Object, _DebounceImpl> _debounces = {};

  /// Runs a debounce operation associated with [key].
  void run(
    Object key,
    void Function() operation, {
    required Duration duration,
  }) {
    final _DebounceImpl debounce = _debounces.putIfAbsent(
      key,
      _DebounceImpl.new,
    );

    debounce.run(
      operation,
      duration: duration,
    );
  }

  void cancel(Object key) {
    _debounces[key]?.cancel();
  }

  /// Disposes and removes the debounce associated with [key].
  void dispose(Object key) {
    final debounce = _debounces.remove(key);
    debounce?.dispose();
  }

  /// Disposes and removes all registered debounces.
  void disposeAll() {
    for (final debounce in _debounces.values) {
      debounce.dispose();
    }

    _debounces.clear();
  }
}
