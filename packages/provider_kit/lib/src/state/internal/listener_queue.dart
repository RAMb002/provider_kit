import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@internal
class ListenerQueue {
  final List<VoidCallback> _callbacks = <VoidCallback>[];

  bool _pending = false;

  bool get isPending => _pending;

  bool get isEmpty => _callbacks.isEmpty;

  void begin() {
    _pending = true;
  }

  void dispatch(VoidCallback callback) {
    if (_pending) {
      _callbacks.add(callback);
      return;
    }

    callback();
  }

  void scheduleInitialListener({
    required VoidCallback initialCallback,
    required bool Function() isMounted,
  }) {
    begin();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (!isMounted()) return;

        initialCallback();
        flush(isMounted: isMounted);
      } finally {
        clear();
      }
    });
  }

  void flush({required bool Function() isMounted}) {
    try {
      int index = 0;

      while (index < _callbacks.length) {
        if (!isMounted()) {
          return;
        }

        final VoidCallback callback = _callbacks[index];
        index++;

        callback();
      }
    } finally {
      _callbacks.clear();
      _pending = false;
    }
  }

  void clear() {
    _callbacks.clear();
    _pending = false;
  }
}
