part of '../multi_state.dart';

extension StateListenableWatch<T> on StateListenable<T> {
  /// Reads the current state and registers this source as a dependency.
  ///
  /// `.watch` can only be used inside a dependency-collecting callback,
  /// such as the `providers` callback of a MultiState widget or the
  /// `builder` callback of a [WatchBuilder].
  T get watch {
    assert(
      _DependencyTracker.isCollecting,
      '$runtimeType.watch can only be used inside a '
      'dependency-collecting callback of a supported ProviderKit widget.',
    );

    if (_DependencyTracker.isCollecting) {
      _DependencyTracker.record(this);
    }

    return state;
  }
}
