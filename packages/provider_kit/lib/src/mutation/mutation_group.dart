// ignore_for_file: invalid_use_of_protected_member

part of 'mutation.dart';

/// Manages multiple independent [Mutation] instances identified by a key.
///
/// A [Mutation] represents the state of one asynchronous operation. However,
/// some UI requires the same operation to be performed independently for
/// multiple items.
///
/// For example, imagine a list of todos where every item has its own
/// delete button. Each todo needs its own mutation state so that deleting
/// one todo does not put every delete button into a loading state.
///
/// [MutationGroup] provides a separate [Mutation] for each key:
///
/// ```dart
/// final deleteTodo = MutationGroup<void>();
///
/// final mutation = deleteTodo(todo.id);
///
/// mutation.run(
///   () => Api.deleteTodo(todo.id),
/// );
/// ```
///
/// Internally, the group maintains one mutation per key:
///
/// ```text
/// deleteTodo
/// ├── 1 → Mutation<void>
/// ├── 2 → Mutation<void>
/// ├── 3 → Mutation<void>
/// └── ...
/// ```
///
/// Each keyed mutation has completely independent state. For example:
///
/// ```text
/// Todo 1 → Loading
/// Todo 2 → Idle
/// Todo 3 → Error
/// ```
///
/// This makes [MutationGroup] particularly useful for list items, where
/// widgets may be created and destroyed as the user scrolls.
///
/// ### Why not create a new Mutation for every item?
///
/// If each list item creates and owns its own [Mutation], that mutation is
/// tied to the lifetime of that item instance. When the item is destroyed,
/// its mutation can become unreachable and its state can be lost.
///
///
/// [MutationGroup] keeps the mutation associated with the item's key rather
/// than the widget instance. When the item is rebuilt, requesting the same key
/// returns the existing mutation while it is still cached.
///
/// ```dart
/// final mutation = deleteTodo(todo.id);
/// ```
///
/// Requesting the same key from the same group instance returns the same
/// [Mutation] instance while that mutation remains cached:
///
/// ```dart
/// final group = MutationGroup<void>();
///
/// final mutationA = group('todo_1');
/// final mutationB = group('todo_1');
///
/// print(identical(mutationA, mutationB)); // true
/// ```
///
/// ### Automatic disposal
///
/// Keyed mutations are automatically removed from the cache when they have
/// no listeners, based on their current state.
///
/// By default:
///
/// - [MutationIdle] is eligible for automatic disposal when unobserved.
/// - [MutationLoading] is always kept alive until the operation completes.
/// - [MutationSuccess] is eligible for automatic disposal when unobserved.
/// - [MutationError] is eligible for automatic disposal when unobserved.
///
/// This prevents the group from retaining every mutation ever created in
/// memory, which is especially important for large or continuously scrolling
/// lists.
///
/// A mutation that is currently loading is kept alive even when it has no
/// listeners. This allows the operation to finish without losing its state
/// while the widget is temporarily absent from the widget tree.
///
/// Once the loading operation finishes, the mutation becomes eligible for
/// automatic disposal according to the configured [keepAliveStates].
///
/// ### Keeping completed states alive
///
/// By default, completed success and error states are automatically disposed
/// when they have no listeners.
///
/// You can preserve either state by adding it to [keepAliveStates]:
///
/// ```dart
/// final group = MutationGroup<void>(
///   keepAliveStates: {
///     KeepAliveState.success,
///   },
/// );
/// ```
///
/// In this example, successful mutations remain cached after their listeners
/// are removed, while idle and error mutations remain eligible for automatic
/// disposal when unobserved.
///
/// To keep both success and error states alive:
///
/// ```dart
/// final group = MutationGroup<void>(
///   keepAliveStates: {
///     KeepAliveState.success,
///     KeepAliveState.error,
///   },
/// );
/// ```
///
/// Keeping completed states alive can be useful when a result needs to remain
/// available after the widget that triggered the operation is temporarily
/// removed from the widget tree.
///
/// Be careful when keeping states alive in large or long-lived groups, as
/// cached mutations remain in memory until they are automatically disposed,
/// manually disposed, or the group itself is disposed.
///
/// ### Manual disposal
///
/// A single keyed mutation can be explicitly disposed with [disposeKey]:
///
/// ```dart
/// deleteTodo.disposeKey(todo.id);
/// ```
///
/// The entire group can be disposed when its owner is disposed:
///
/// ```dart
/// @override
/// void dispose() {
///   deleteTodo.dispose();
///   super.dispose();
/// }
/// ```
///
/// Disposing the group immediately disposes all currently cached mutations,
/// including mutations that are still loading.
///
/// ### When should I use MutationGroup?
///
/// Use a [Mutation] when one operation has one shared state:
///
/// ```dart
/// final logout = Mutation<void>();
/// ```
///
/// Use a [MutationGroup] when the same operation needs independent state
/// for multiple keys:
///
/// ```dart
/// final deleteTodo = MutationGroup<void>();
///
/// deleteTodo(todo1.id); // independent state
/// deleteTodo(todo2.id); // independent state
/// deleteTodo(todo3.id); // independent state
/// ```
///
/// The group is especially useful when the key represents an entity ID,
/// list item ID, or any other value that uniquely identifies the operation.
///
/// [MutationGroup] manages the keyed mutation instances internally; callers
/// only interact with the [Mutation] returned for each key.
class MutationGroup<T> {
  final Map<Object, Mutation<T>> _cache = {};
  final Map<Object, _AutoDisposeController<T, Object>> _controllers = {};
  final Set<KeepAliveState> _keepAliveStates;

  /// Creates a group that manages keyed mutations with automatic disposal.
  ///
  /// By default, unobserved [MutationIdle], [MutationSuccess], and
  /// [MutationError] states are eligible for automatic disposal.
  ///
  /// [MutationLoading] is always kept alive until the operation completes.
  ///
  /// Use [keepAliveStates] to preserve completed success or error states after
  /// their listeners are removed.
  ///
  /// For example, to keep successful mutations alive:
  ///
  /// ```dart
  /// final group = MutationGroup<void>(
  ///   keepAliveStates: {
  ///     KeepAliveState.success,
  ///   },
  /// );
  /// ```
  ///
  /// To keep both success and error states alive:
  ///
  /// ```dart
  /// final group = MutationGroup<void>(
  ///   keepAliveStates: {
  ///     KeepAliveState.success,
  ///     KeepAliveState.error,
  ///   },
  /// );
  /// ```
  ///
  /// The provided set is copied and cannot be modified after the group is
  /// created.
  MutationGroup({
    Set<KeepAliveState> keepAliveStates = const {},
  }) : _keepAliveStates = Set.unmodifiable(keepAliveStates);

  /// Returns the [Mutation] associated with [key].
  ///
  /// If a mutation for [key] is already cached, the existing instance is
  /// returned. Otherwise, a new mutation is created and cached.
  ///
  /// The same key therefore refers to the same mutation instance while that
  /// mutation remains cached.
  Mutation<T> call(Object key) {
    final existing = _cache[key];
    if (existing != null && existing.mounted) {
      return existing;
    }

    final mutation = Mutation<T>();
    _setupMutation(key, mutation);
    _cache[key] = mutation;
    return mutation;
  }

  void _setupMutation(Object key, Mutation<T> mutation) {
    late final _AutoDisposeController<T, Object> controller;

    controller = _AutoDisposeController(
      key: key,
      mutation: mutation,
      shouldDispose: _shouldDispose,
      onDispose: _autoDispose,
    );

    controller.attach();

    mutation._setOnDisposed(() {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _cache.remove(key);
    });

    _controllers[key]?.dispose();
    _controllers[key] = controller;
  }

  bool _shouldDispose(Mutation<T> mutation) {
    // Must have no listeners
    if (mutation.hasListeners) return false;

    final state = mutation.state;

    return switch (state) {
      MutationIdle<T>() => true,
      MutationLoading<T>() => false,
      MutationSuccess<T>() =>
        !_keepAliveStates.contains(KeepAliveState.success),
      MutationError<T>() => !_keepAliveStates.contains(KeepAliveState.error),
    };
  }

  /// Disposes the mutation associated with [key].
  ///
  /// If no mutation exists for [key], this method does nothing.
  ///
  /// This forces disposal even if the mutation is currently loading.
  void disposeKey(Object key) {
    _cleanup(key, force: true);
  }

  /// Disposes all mutations currently managed by this group.
  ///
  /// This also disposes mutations that are currently loading.
  void dispose() {
    while (_cache.isNotEmpty) {
      final key = _cache.keys.first;
      _cleanup(key, force: true);
    }
  }

  void _autoDispose(Object key) {
    _cleanup(key, force: false);
  }

  void _cleanup(Object key, {required bool force}) {
    final mutation = _cache[key];
    if (mutation == null) return;

    // Respect policy only for auto dispose
    if (!force && !_shouldDispose(mutation)) return;

    _cache.remove(key);
    _controllers[key]?.dispose();
    _controllers.remove(key);

    if (mutation.mounted) {
      mutation.dispose();
    }
  }
}

class _AutoDisposeController<T, K> {
  final K key;
  final Mutation<T> mutation;
  final bool Function(Mutation<T> mutation) shouldDispose;
  final void Function(K key) onDispose;

  _AutoDisposeController({
    required this.key,
    required this.mutation,
    required this.shouldDispose,
    required this.onDispose,
  });

  void attach() {
    mutation._setOnFirstListenerAdded(_onFirstListener);
    mutation._setOnLastListenerRemoved(_onLastListener);
    mutation._setOnStateChanged(_onStateChanged);
  }

  bool _queued = false;

  void _onFirstListener() {
    _queued = false;
  }

  void _onLastListener() {
    if (shouldDispose(mutation)) {
      _scheduleDispose();
    }
  }

  void _onStateChanged() {
    if (!mutation.mounted) return;
    if (!mutation.isLoading && shouldDispose(mutation)) {
      _scheduleDispose();
    }
  }

  void _scheduleDispose() {
    if (_queued) return;
    _queued = true;
    scheduleMicrotask(() {
      _queued = false;
      if (!mutation.mounted) return;
      if (!shouldDispose(mutation)) return;
      onDispose(key);
    });
  }

  void dispose() {
    mutation._setOnFirstListenerAdded(null);
    mutation._setOnLastListenerRemoved(null);
    mutation._setOnStateChanged(null);
    mutation._setOnDisposed(null);
  }
}

enum KeepAliveState {
  success,
  error,
}