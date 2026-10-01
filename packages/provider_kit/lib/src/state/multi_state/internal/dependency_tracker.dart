part of '../multi_state.dart';

class _DependencyTracker {
  _DependencyTracker._();

  static final List<Set<StateValueListenable>> _collectors = [];

  static bool get isCollecting => _collectors.isNotEmpty;

  static void record(StateValueListenable listenable) {
    if (_collectors.isEmpty) {
      return;
    }

    _collectors.last.add(listenable);
  }

  static _DependencyCollection<T> collect<T>(
    T Function() providers, {
    required String widgetName,
  }) {
    final dependencies = Set<StateValueListenable>.identity();

    _collectors.add(dependencies);

    try {
      final value = providers();

      assert(
        dependencies.isNotEmpty,
        '$widgetName requires at least one watched state source.\n\n'
        'Use `.watch` inside the `providers` callback.\n\n'
        'Example:\n'
        'providers: () => (\n'
        '  user: userProvider.watch,\n'
        '  loading: loadingField.watch,\n'
        ')',
      );

      return _DependencyCollection<T>(
        value: value,
        dependencies: dependencies,
      );
    } finally {
      _collectors.removeLast();
    }
  }
}

class _DependencyCollection<T> {
  const _DependencyCollection({
    required this.value,
    required this.dependencies,
  });

  final T value;

  final Set<StateValueListenable> dependencies;
}
