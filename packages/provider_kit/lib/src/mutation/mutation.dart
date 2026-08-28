// ignore_for_file: invalid_use_of_protected_member
library provider_kit_mutation;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/observer/change.dart';

part 'mutation_group.dart';
part 'mutation_state.dart';

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
/// ### Basic usage
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
///       error: (error, stackTrace, errorInfo) => const Icon(Icons.error),
///     );
///   },
/// );
/// ```
///
/// ### Reusing a mutation
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
/// ### Concurrent executions
///
/// Multiple executions may run at the same time. Only the most recently
/// started execution is allowed to publish a final mutation state.
///
/// Earlier executions continue running and still return their own results or
/// rethrow their own errors, but their results cannot overwrite a newer
/// mutation state or a state established by [reset].
///
///
/// ### Mutations for multiple items
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
/// ### Disposing
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
  /// - The mapped error information is available through [MutationError.errorInfo].
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
