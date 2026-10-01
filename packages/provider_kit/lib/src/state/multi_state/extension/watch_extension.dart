part of '../multi_state.dart';

extension StateValueListenableWatch<T> on StateValueListenable<T> {
  T get watch {
    assert(
      _DependencyTracker.isCollecting,
      '''
StateValueListenable.watch can only be used inside
the `providers` callback of a MultiState widget.
''',
    );

    if (_DependencyTracker.isCollecting) {
      _DependencyTracker.record(this);
    }

    return state;
  }
}
