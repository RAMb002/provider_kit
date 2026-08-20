// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/notifier_base.dart';
import 'package:provider_kit/src/base/observer/change.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';

/// Manages the state of an asynchronous operation.
///
/// A [Mutation] is useful for operations that change data or application
/// state, such as:
///
/// - Creating, updating, or deleting data.
/// - Logging in or logging out.
/// - Submitting a form.
/// - Sending a message.
/// - Uploading a file.
/// - Performing an action in response to a user interaction.
///
/// A mutation moves through the following states:
///
/// ```text
/// Idle → Loading → Success
///              ↘ Error
/// ```
///
/// ## Basic usage
///
/// Create a mutation in the class that owns the operation, such as a provider
/// or controller, and reuse the same instance whenever the operation is
/// performed.
///
/// ```dart
/// class TodoProvider {
///   final deleteTodo = Mutation<void>();
///
///   Future<void> delete(int id) {
///     return deleteTodo.run(
///       () => Api.deleteTodo(id),
///     );
///   }
///
///   void dispose() {
///     deleteTodo.dispose();
///   }
/// }
/// ```
///
/// The mutation can then be provided to a [StateBuilder] to react to its
/// state.
///
/// ```dart
/// StateBuilder<MutationState<void>>(
///   provider: provider.deleteTodo,
///   builder: (context, state, child) {
///     return state.when(
///       idle: () => const Text('Delete'),
///       loading: () => const CircularProgressIndicator(),
///       success: (_) => const Icon(Icons.check),
///       error: (error, stackTrace) => const Icon(Icons.error),
///     );
///   },
/// );
/// ```
///
/// ## Reusing a mutation
///
/// A [Mutation] is stateful and should normally be created once and reused.
/// Keep the mutation in the provider, controller, or other object that owns
/// the operation, and call [run] whenever the operation needs to be performed.
///
/// Calling [run] does not create a new mutation. It updates the state of the
/// existing instance, allowing its loading, success, and error states to be
/// observed consistently.
///
/// Do not create a mutation inside a widget's [build] method:
///
/// ```dart
/// Widget build(BuildContext context) {
///   final mutation = Mutation<void>(); // ❌
///   ...
/// }
/// ```
///
/// A widget can rebuild many times. Creating the mutation during [build]
/// would create a new instance on each rebuild, causing the previous mutation
/// state to be lost.
///
/// Instead, keep the mutation outside the widget's [build] method and provide
/// the same instance to the widget that needs to observe it.
///
/// ## Concurrent executions
///
/// Multiple executions may run at the same time. Only the most recently
/// started execution is allowed to publish a final mutation state.
///
/// Earlier executions continue running and still return their own results or
/// rethrow their own errors, but their results cannot overwrite a newer
/// mutation state or a state established by [reset].
///
///
/// ## Mutations for multiple items
///
/// When an operation needs an independent state for multiple items, use
/// [MutationGroup].
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
/// Each key has its own [Mutation] and therefore its own loading, success,
/// and error state. This is particularly useful for operations performed
/// from list items, where each item needs to display its own loading state.
///
/// Keyed mutations are automatically disposed when they no longer have
/// listeners and are not currently loading. A mutation that is still
/// executing is kept alive until the operation completes, even if its
/// widget is removed from the widget tree unless the group itself is disposed.
///
/// ## Disposing
///
/// A [Mutation] should be disposed when the object that owns it is disposed.
///
/// ```dart
/// @override
/// void dispose() {
///   deleteTodo.dispose();
///   super.dispose();
/// }
/// ```
///
/// For [MutationGroup], disposing the group also disposes all of its
/// currently cached mutations.
///
/// See also:
///
/// - [MutationState], which represents the current state.
/// - [MutationGroup], for maintaining independent mutation states by key.
class Mutation<T> extends NotifierBase<MutationState<T>>
    implements StateValueListenable<MutationState<T>> {
  /// Creates a mutation in the [MutationIdle] state.
  Mutation();

  MutationState<T> _state = MutationIdle<T>._();

  @override
  MutationState<T> get state => _state;

  int _runGeneration = 0;

  /// Executes [executor] and updates the mutation state according to
  /// the result.
  ///
  /// The mutation changes to [MutationLoading] before [executor] starts.
  ///
  /// If [executor] completes successfully:
  ///
  /// - The mutation changes to [MutationSuccess].
  /// - The result is returned from [run].
  ///
  /// If [executor] throws:
  ///
  /// - The mutation changes to [MutationError].
  /// - The original error is rethrown.
  ///
  /// This allows the operation to be handled both reactively through
  /// [state] and imperatively through the returned [Future].
  ///
  /// ```dart
  /// final result = await mutation.run(
  ///   () => Api.createTodo(todo),
  /// );
  /// ```
  ///
  /// The executor is supplied when [run] is called, so the same mutation
  /// can be reused for different executions.
  ///
  /// Multiple [run] calls may execute concurrently. Each execution is assigned
  /// a generation, and only the most recently started execution can update the
  /// mutation state.
  ///
  /// Earlier executions are not cancelled and still complete normally. However,
  /// if a newer [run] call is started or [reset] is called before an earlier
  /// execution completes, that earlier execution becomes stale and can no longer
  /// update the mutation state.
  ///
  /// This ensures that stale asynchronous results cannot overwrite the state
  /// produced by a newer execution.
  ///
  /// If concurrent executions are not intended, add an appropriate guard
  /// before calling [run].
  Future<T> run(Future<T> Function() executor) async {
    assert(NotifierBase.debugAssertNotDisposed(this, 'run'));

    final generation = ++_runGeneration;

    _setState(MutationLoading<T>._());

    try {
      final result = await executor();

      if (!mounted || generation != _runGeneration) return result;

      _setState(MutationSuccess<T>._(result));
      return result;
    } catch (error, stackTrace) {
      if (!mounted || generation != _runGeneration) rethrow;

      _setState(MutationError<T>._(error, stackTrace));
      onError(error, stackTrace);
      rethrow;
    }
  }

  /// Resets the mutation to [MutationIdle].
  ///
  /// This clears the current success or error state and invalidates any
  /// in-flight execution, preventing that execution from updating the mutation
  /// state when it completes.
  void reset() {
    assert(NotifierBase.debugAssertNotDisposed(this, 'reset'));
    ++_runGeneration;
    _setState(MutationIdle<T>._());
  }

  void _setState(MutationState<T> newState) {
    assert(NotifierBase.debugAssertNotDisposed(this, 'setState'));

    if (!mounted) return;

    if (_state == newState) return;

    try {
      onChange(
        Change<MutationState<T>>(
          currentState: _state,
          nextState: newState,
        ),
      );

      _state = newState;
      notifyListeners();
      _onStateChanged?.call();
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
  }

  /// Whether the mutation has not been executed yet.
  bool get isIdle => _state.isIdle;

  /// Whether the mutation is currently executing.
  bool get isLoading => _state.isLoading;

  /// Whether the mutation completed successfully.
  bool get isSuccess => _state.isSuccess;

  /// Whether the mutation failed.
  bool get isError => _state.isError;

  /// Returns the result of the current [MutationSuccess] state.
  ///
  /// Returns `null` when the mutation is not currently successful.
  T? get data {
    final currentState = _state;

    return currentState is MutationSuccess<T> ? currentState.data : null;
  }

  VoidCallback? _onFirstListenerAdded;
  VoidCallback? _onLastListenerRemoved;
  VoidCallback? _onStateChanged;
  VoidCallback? _onDisposed;

  /// Internal: called by MutationGroup only.
  void _setOnFirstListenerAdded(VoidCallback? callback) {
    _onFirstListenerAdded = callback;
  }

  /// Internal: called by MutationGroup only.
  void _setOnLastListenerRemoved(VoidCallback? callback) {
    _onLastListenerRemoved = callback;
  }

  /// Internal: called by MutationGroup only.
  void _setOnStateChanged(VoidCallback? callback) {
    _onStateChanged = callback;
  }

  /// Internal: called by MutationGroup only.
  void _setOnDisposed(VoidCallback? callback) {
    _onDisposed = callback;
  }

  @override
  void addListener(VoidCallback listener) {
    final wasEmpty = !hasListeners;
    super.addListener(listener);
    if (wasEmpty) {
      _onFirstListenerAdded?.call();
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _onLastListenerRemoved?.call();
    }
  }

  @override
  void dispose() {
    _onDisposed?.call();
    _onFirstListenerAdded = null;
    _onLastListenerRemoved = null;
    _onStateChanged = null;
    _onDisposed = null;
    super.dispose();
  }
}

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
/// ## Why not create a new Mutation for every item?
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
/// ## Automatic disposal
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
/// ## Keeping completed states alive
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
/// ## Manual disposal
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
/// ## When should I use MutationGroup?
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

/// {@template provider_kit.mutation_state}
/// Represents the current state of a mutation operation.
///
/// A mutation can be in one of four states:
///
/// - [MutationIdle] when no operation has been executed.
/// - [MutationLoading] while the operation is executing.
/// - [MutationSuccess] when the operation completes successfully.
/// - [MutationError] when the operation fails.
/// {@endtemplate}
@immutable
sealed class MutationState<T> {
  const MutationState._();

  /// {@template provider_kit.mutation_state.when}
  /// Executes the callback corresponding to the current state.
  ///
  /// All possible mutation states must be handled.
  ///
  /// This is useful when the UI or business logic needs to react
  /// differently to each state.
  /// {@endtemplate}
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(
      Object error,
      StackTrace stackTrace,
    ) error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle(),
      MutationLoading<T>() => loading(),
      MutationSuccess<T>() => success(state.data),
      MutationError<T>() => error(state.error, state.stackTrace),
    };
  }

  /// {@template provider_kit.mutation_state.map}
  /// Maps the current mutation state to another value.
  ///
  /// Unlike [when], the callbacks receive the complete state object,
  /// allowing access to state-specific properties.
  /// {@endtemplate}
  R map<R>({
    required R Function(MutationIdle<T> idle) idle,
    required R Function(MutationLoading<T> loading) loading,
    required R Function(MutationSuccess<T> success) success,
    required R Function(MutationError<T> error) error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle(state),
      MutationLoading<T>() => loading(state),
      MutationSuccess<T>() => success(state),
      MutationError<T>() => error(state),
    };
  }

  /// {@template provider_kit.mutation_state.maybe_when}
  /// Executes the matching callback when one is provided.
  ///
  /// If no callback is provided for the current state, [orElse] is
  /// executed instead.
  ///
  /// This is useful when only a subset of mutation states needs to
  /// be handled.
  /// {@endtemplate}
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? success,
    R Function(
      Object error,
      StackTrace stackTrace,
    )? error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle != null ? idle() : orElse(),
      MutationLoading<T>() => loading != null ? loading() : orElse(),
      MutationSuccess<T>() => success != null ? success(state.data) : orElse(),
      MutationError<T>() =>
        error != null ? error(state.error, state.stackTrace) : orElse(),
    };
  }

  /// {@template provider_kit.mutation_state.maybe_map}
  /// Maps the current mutation state when a matching mapper is provided.
  ///
  /// If no mapper is provided for the current state, [orElse] is
  /// executed instead.
  ///
  /// Unlike [maybeWhen], the mapper receives the complete state object.
  /// {@endtemplate}
  R maybeMap<R>({
    required R Function() orElse,
    R Function(MutationIdle<T> idle)? idle,
    R Function(MutationLoading<T> loading)? loading,
    R Function(MutationSuccess<T> success)? success,
    R Function(MutationError<T> error)? error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle != null ? idle(state) : orElse(),
      MutationLoading<T>() => loading != null ? loading(state) : orElse(),
      MutationSuccess<T>() => success != null ? success(state) : orElse(),
      MutationError<T>() => error != null ? error(state) : orElse(),
    };
  }

  /// Whether no mutation operation has been executed yet.
  bool get isIdle => this is MutationIdle<T>;

  /// Whether a mutation operation is currently executing.
  bool get isLoading => this is MutationLoading<T>;

  /// Whether the mutation operation completed successfully.
  bool get isSuccess => this is MutationSuccess<T>;

  /// Whether the mutation operation failed.
  bool get isError => this is MutationError<T>;
}

/// {@template provider_kit.mutation_idle}
/// Indicates that no mutation operation has been executed yet.
/// {@endtemplate}
final class MutationIdle<T> extends MutationState<T> {
  const MutationIdle._() : super._();

  @override
  bool operator ==(Object other) => other is MutationIdle<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// {@template provider_kit.mutation_loading}
/// Indicates that a mutation operation is currently executing.
/// {@endtemplate}
final class MutationLoading<T> extends MutationState<T> {
  const MutationLoading._() : super._();

  @override
  bool operator ==(Object other) => other is MutationLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// {@template provider_kit.mutation_success}
/// Indicates that a mutation operation completed successfully.
///
/// The result of the operation is available through [data].
/// {@endtemplate}
final class MutationSuccess<T> extends MutationState<T> {
  /// Creates a successful mutation state containing [data].
  const MutationSuccess._(this.data) : super._();

  /// The result produced by the successful mutation operation.
  final T data;

  @override
  bool operator ==(Object other) =>
      other is MutationSuccess<T> &&
      runtimeType == other.runtimeType &&
      data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// {@template provider_kit.mutation_error}
/// Indicates that a mutation operation failed.
///
/// The error thrown by the operation is available through [error],
/// and its associated [StackTrace] is available through [stackTrace].
/// {@endtemplate}
final class MutationError<T> extends MutationState<T> {
  const MutationError._(
    this.error,
    this.stackTrace,
  ) : super._();

  /// The error thrown during the mutation operation.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace stackTrace;

  @override
  bool operator ==(Object other) =>
      other is MutationError<T> &&
      runtimeType == other.runtimeType &&
      other.error == error &&
      other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(error, stackTrace);
}
