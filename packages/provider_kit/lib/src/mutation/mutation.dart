// ignore_for_file: invalid_use_of_protected_member
library provider_kit_mutation;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/state_listenable.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/mutation/type_defs.dart';
import 'package:provider_kit/src/observer/change.dart';
import 'package:provider_kit/src/utils/generation_guard.dart';

part 'internals/mutation_concurrency_handler.dart';
part 'internals/mutation_execution.dart';
part 'mutation_concurrency.dart';
part 'mutation_group.dart';
part 'mutation_result.dart';
part 'mutation_state.dart';

/// {@template provider_kit.mutation}
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
///            ┌──→ Success
/// Idle → Loading
///            └──→ Error
/// ```
/// A [Mutation] implements [StateListenable] and can be listened to directly
/// to react to changes in its [MutationState].
///
/// When an action fails, the observable state becomes [MutationError],
/// while the corresponding execution result is [MutationErrored].
/// Both contain the original error, stack trace, and mapped [ErrorInfo].
///
/// ### Basic usage
///
/// Create a mutation in the class that owns the operation, such as a provider
/// or controller, and reuse the same instance whenever the operation is
/// performed.
///
/// ```dart
/// class AuthProvider {
///   final signInMutation = Mutation<User>();
///
///   Future<MutationResult<User>> signIn(String email) {
///     return signInMutation.run(
///       () => Api.signIn(email),
///     );
///   }
///
///   void dispose() {
///     signInMutation.dispose();
///   }
/// }
/// ```
///
/// The mutation can then be provided to a `StateBuilder` or a `StateListener`
/// to react to its state.
///
/// ```dart
/// StateBuilder.of<AuthProvider, MutationState<User>>(
///   selectListenable: (AuthProvider provider) => provider.signInMutation,
///   builder: (context, state, child) {
///     return state.when(
///       idle: () => const Text('SignIn'),
///       loading: () => const CircularProgressIndicator(),
///       success: (user) => const Icon(Icons.check),
///       error: (errorInfo, error, stackTrace) => Text(errorInfo.message),
///     );
///   },
/// );
/// ```
///
/// ### Execution callbacks
///
/// [run] provides optional `onSuccess` and `onError` callbacks for handling the outcome
/// of an individual execution.
///
/// ```dart
/// await signInMutation.run(
///   () => Api.signIn(email),
///   onSuccess: (user) {
///     // e.g. currentUser = user
///   },
///   onError: (error, stackTrace) {
///     // handle error here
///   },
/// );
/// ```
///
/// Callbacks follow the mutation's concurrency policy. They are invoked
/// only when the execution is allowed to commit its outcome. Superseded,
/// rejected, or invalidated executions do not invoke their callbacks.
/// Queued executions invoke their callbacks when they are processed.
///
/// Executions invalidated by [reset] or disposal before their outcome is
/// committed do not invoke their callbacks.
///
/// ### Execution results
///
/// [run] returns a [MutationResult] describing the outcome of that specific
/// execution:
///
/// - [MutationSucceeded] contains the successful result in its `data`
///   property.
/// - [MutationErrored] contains the original error, stack trace, and mapped
///   [ErrorInfo].
/// - [MutationIgnored] indicates that the execution was rejected or
///   invalidated, along with the reason.
///
/// Operation errors are returned as [MutationErrored] rather than being
/// rethrown. Errors thrown by `onSuccess` or `onError` callbacks complete
/// the returned future with the callback error. They do not change the
/// already-published mutation state.
///
/// An execution can be ignored when it is rejected by
/// [MutationConcurrency.ignoreIfBusy], superseded by
/// [MutationConcurrency.latestOnly], or invalidated by [reset] or disposal.
/// These executions complete with [MutationIgnored].
///
/// Use the returned result when the caller needs to handle the outcome of a
/// particular execution, such as showing a message, navigating, or deciding
/// whether to perform another operation.
///
/// ```
/// final result = await signInMutation.run(
///   () => Api.signIn(email),
/// );
///
/// result.when(
///   succeeded: (user) {
///     Navigator.of(context).push(DashBoardView());
///   },
///   errored: (errorInfo, error, stackTrace) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(errorInfo.message)),
///     );
///   },
///   ignored: (ignoreReason) {
///     // No action is usually necessary for an ignored execution.
///   },
/// );
/// ```
///
/// Use [MutationState] when the UI needs to reactively display the mutation's
/// current state. Use [MutationResult] when the caller needs to handle the
/// outcome of a specific execution.
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
/// ### Concurrent executions
///
/// The concurrency policy determines how overlapping calls to [run] are
/// handled. Available policies are provided by [MutationConcurrency]:
///
/// - [MutationConcurrency.parallel]: Runs every execution concurrently.
/// - [MutationConcurrency.latestOnly]: Only the latest execution outcome can
///   be committed. Earlier executions continue running, but their
///   outcomes are ignored.
/// - [MutationConcurrency.ignoreIfBusy]: Ignores new executions while another
///   execution is active.
/// - [MutationConcurrency.queue]: Runs executions sequentially in FIFO order.
///
/// By default, mutations use [MutationConcurrency.parallel]. This default can
/// be changed globally through [ProviderKit.configure], or overridden for
/// individual mutations using the [Mutation] constructor.
///
/// ```dart
/// final saveMutation = Mutation<void>(
///   concurrency: MutationConcurrency.ignoreIfBusy,
/// );
/// ```
///
/// ### Mutations for multiple items
///
/// When an operation needs independent state for multiple items, use
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
/// Each key has its own cached [Mutation] instance, with independent state
/// and execution handling. Repeated lookups for the same key return the
/// existing mutation while it remains cached.
///
/// Each keyed mutation uses the concurrency policy configured by the group.
/// The group inherits the application-wide default unless an explicit
/// concurrency policy is provided.
///
/// Keyed mutations are automatically disposed when they have no listeners
/// and no pending executions. You can configure the group to keep successful or
/// failed mutations alive instead.
///
/// ### Resetting
///
/// Call [reset] to clear the current success or error state and return the
/// mutation to [MutationIdle].
///
/// Resetting also invalidates active executions whose outcomes have not yet
/// been committed and ignores executions waiting in the queue. Their
/// underlying asynchronous actions are not cancelled, but their eventual
/// outcomes are ignored.
///
/// ### Disposing
///
/// A [Mutation] should be disposed when the object that owns it is disposed.
///
/// ```dart
/// @override
/// void dispose() {
///   signInMutation.dispose();
/// }
/// ```
///
/// Disposing a mutation prevents further state updates and invalidates active
/// executions whose outcomes have not yet been committed. Queued executions
/// are also ignored.
///
/// Disposing a [MutationGroup] also disposes all of its currently cached
/// mutations.
///
/// ### Do not create mutations in build
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
/// See also:
///
/// - [MutationState], which represents the current mutation state.
/// - [MutationResult], which represents an individual execution outcome.
/// - [MutationConcurrency], for available concurrency policies.
/// - [MutationGroup], for maintaining independent mutation states by key.
/// {@endtemplate}
final class Mutation<T> extends NotifierBase<MutationState<T>>
    implements StateListenable<MutationState<T>> {
  /// {@macro provider_kit.mutation}
  Mutation({MutationConcurrency? concurrency})
    : _concurrencyHandler = _MutationConcurrencyHandler<T>(
        concurrency ?? ProviderKit.defaultMutationConcurrency,
      );

  MutationState<T> _state = MutationIdle<T>._();

  @override
  MutationState<T> get state => _state;

  /// Owns execution scheduling and concurrency bookkeeping.
  final _MutationConcurrencyHandler<T> _concurrencyHandler;

  /// Whether this mutation has executions that haven't completed.
  bool get _hasPendingExecutions => _concurrencyHandler.hasPendingExecutions;

  final GenerationGuard _stateChangeGuard = GenerationGuard();

  /// Executes [action] and returns a [MutationResult] for this invocation.
  ///
  /// ### State changes
  ///
  /// When an execution starts, the mutation enters [MutationLoading].
  /// When the action succeeds, it publishes [MutationSuccess]. When the
  /// action fails, it publishes [MutationError] and dispatches the error.
  ///
  /// An execution that is rejected or invalidated before its outcome is
  /// committed does not publish a success or error state.
  ///
  /// An outcome is committed once the action finishes and the execution is
  /// accepted for publication. From that point, [reset] and newer executions
  /// do not retroactively invalidate it.
  ///
  /// ### Execution results
  ///
  /// The returned [MutationResult] describes the outcome of this specific
  /// execution:
  ///
  /// - [MutationSucceeded] contains the successful result in its `data`
  ///   property.
  /// - [MutationErrored] contains the original error, stack trace, and mapped
  ///   [ErrorInfo]. Action errors are returned rather than rethrown.
  /// - [MutationIgnored] indicates that the execution was rejected or
  ///   invalidated, along with the reason.
  ///
  /// An execution can be ignored when rejected by
  /// [MutationConcurrency.ignoreIfBusy], superseded by
  /// [MutationConcurrency.latestOnly], or invalidated by [reset] or disposal.
  /// Calling [run] on a disposed mutation also returns [MutationIgnored]
  /// with [MutationIgnoreReason.disposed] (and asserts in debug mode).
  ///
  /// ### Callbacks
  ///
  /// [onSuccess] and [onError] are optional callbacks belonging to this
  /// invocation. They run after the corresponding mutation state has been
  /// updated and can be synchronous or asynchronous. Asynchronous callbacks
  /// are awaited before the returned future completes.
  ///
  /// Callback invocation follows the configured [concurrency] policy.
  /// Rejected, superseded, or invalidated executions do not invoke their
  /// callbacks. Queued executions invoke their callbacks when processed.
  ///
  /// Errors thrown by [onSuccess] or [onError] complete the returned future
  /// with the callback error instead of an execution result. They do not
  /// change the already-published mutation state.
  ///
  /// Running actions are not cancelled when superseded, reset, or disposed.
  /// Their side effects may still occur, but uncommitted outcomes are ignored.
  /// Callbacks that have already started are allowed to finish.
  ///
  /// ```dart
  /// final result = await mutation.run(
  ///   () => Api.createTodo(todo),
  ///   onSuccess: (todo) => cache.add(todo),
  /// );
  ///
  /// result.when(
  ///   succeeded: (todo) => showCreated(todo),
  ///   errored: (errorInfo, error, stackTrace) => showError(errorInfo.message),
  ///   ignored: (reason) {},
  /// );
  /// ```
  Future<MutationResult<T>> run(
    MutationActionCallback<T> action, {
    MutationSuccessCallback<T>? onSuccess,
    MutationErrorCallback? onError,
  }) async {
    assert(NotifierBase.debugAssertNotDisposed(this, 'run'));

    if (!mounted) {
      return Future<MutationResult<T>>.value(
        MutationIgnored<T>._(MutationIgnoreReason.disposed),
      );
    }

    final execution = _MutationExecution<T>(
      action: action,
      onSuccess: onSuccess,
      onError: onError,
    );

    switch (_concurrencyHandler.schedule(execution)) {
      case _ExecutionSchedule.start:
        _startExecution(execution);
        break;
      case _ExecutionSchedule.queued:
        break;
      case _ExecutionSchedule.ignored:
        _completeIgnored(
          execution,
          execution.ignoreReason ?? MutationIgnoreReason.disposed,
        );
        break;
    }

    return execution.completer.future;
  }

  /// Starts an execution that the concurrency handler has already reserved.
  void _startExecution(_MutationExecution<T> execution) {
    if (!mounted) {
      _completeIgnored(execution, MutationIgnoreReason.disposed);
      return;
    }

    _setState(MutationLoading<T>._());

    // State notifications can synchronously trigger reset(), dispose(),
    // or another run(). Re-check before invoking the action.
    final reason = _getIgnoreReason(execution);
    if (reason != null) {
      _completeIgnored(execution, reason);
      return;
    }

    unawaited(_execute(execution));
  }

  MutationIgnoreReason? _getIgnoreReason(_MutationExecution<T> execution) {
    if (execution.ignoreReason != null) {
      return execution.ignoreReason;
    }

    if (!mounted && !execution.outcomeCommitted) {
      execution.ignoreReason = MutationIgnoreReason.disposed;
    }

    return execution.ignoreReason;
  }

  Future<void> _execute(_MutationExecution<T> execution) async {
    late final T data;

    try {
      data = await execution.action();
    } catch (error, stackTrace) {
      await _finishFailure(execution, error, stackTrace);
      return;
    }

    await _finishSuccess(execution, data);
  }

  Future<void> _finishSuccess(_MutationExecution<T> execution, T data) async {
    if (!_tryCommitOutcome(execution)) return;

    try {
      _setState(MutationSuccess<T>._(data));

      if (mounted) {
        await execution.onSuccess?.call(data);
      }
    } catch (error, stackTrace) {
      _completeWithError(execution, error, stackTrace);
      return;
    }

    _completeWithResult(execution, MutationSucceeded<T>._(data));
  }

  Future<void> _finishFailure(
    _MutationExecution<T> execution,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!_tryCommitOutcome(execution)) return;

    late final ErrorInfo errorInfo;

    try {
      // Resolve once and share the same ErrorInfo between state and result.
      errorInfo = ProviderKit.resolveErrorInfo(error, stackTrace);
      _setState(MutationError<T>._(error, stackTrace, errorInfo));

      if (mounted) {
        dispatchError(error, stackTrace);
        await execution.onError?.call(error, stackTrace);
      }
    } catch (callbackError, callbackStackTrace) {
      _completeWithError(execution, callbackError, callbackStackTrace);
      return;
    }

    _completeWithResult(
      execution,
      MutationErrored<T>._(error, stackTrace, errorInfo),
    );
  }

  void _completeWithResult(
    _MutationExecution<T> execution,
    MutationResult<T> result,
  ) {
    _completeExecution(execution, () => execution.completer.complete(result));
  }

  void _completeWithError(
    _MutationExecution<T> execution,
    Object error,
    StackTrace stackTrace,
  ) {
    _completeExecution(
      execution,
      () => execution.completer.completeError(error, stackTrace),
    );
  }

  void _completeIgnored(
    _MutationExecution<T> execution,
    MutationIgnoreReason reason,
  ) {
    if (execution.completer.isCompleted) return;

    execution.ignoreReason ??= reason;
    _completeWithResult(
      execution,
      MutationIgnored<T>._(execution.ignoreReason!),
    );
  }

  void _completeExecution(
    _MutationExecution<T> execution,
    VoidCallback completeFuture,
  ) {
    if (execution.completer.isCompleted) return;

    final nextExecution = _concurrencyHandler.complete(execution);

    completeFuture();

    // Start a reserved queue item before notifying MutationGroup. This keeps
    // the pending-work check accurate and ensures a group cannot dispose the
    // mutation between consecutive queued executions.
    if (nextExecution != null) {
      _startExecution(nextExecution);
    }

    _onExecutionCompleted?.call();
  }

  bool _tryCommitOutcome(_MutationExecution<T> execution) {
    final reason = _getIgnoreReason(execution);

    if (reason != null) {
      _completeIgnored(execution, reason);
      return false;
    }
    // From this point, reset() and newer runs do not retroactively invalidate
    // this outcome or a callback that has already started.
    execution.outcomeCommitted = true;
    return true;
  }

  /// Resets the mutation to [MutationIdle], clearing its current state.
  ///
  /// Active executions whose outcomes have not yet been committed are
  /// invalidated. Executions waiting in the queue are completed with
  /// [MutationIgnored] using [MutationIgnoreReason.reset].
  ///
  /// Resetting does not cancel underlying asynchronous actions. Their eventual
  /// outcomes are ignored.
  void reset() {
    assert(NotifierBase.debugAssertNotDisposed(this, 'reset'));

    final queuedExecutions = _concurrencyHandler.reset();
    for (final execution in queuedExecutions) {
      _completeIgnored(execution, MutationIgnoreReason.reset);
    }

    _setState(MutationIdle<T>._());
  }

  void _setState(MutationState<T> newState) {
    assert(NotifierBase.debugAssertNotDisposed(this, 'setState'));

    if (!mounted) return;

    // Invalidate any previously pending state transition.
    final generation = _stateChangeGuard.next();

    if (_state == newState) return;

    dispatchChange(
      Change<MutationState<T>>(currentState: _state, nextState: newState),
    );

    if (!mounted || !_stateChangeGuard.isCurrent(generation)) return;

    _state = newState;
    notifyListeners();

    if (!mounted || !_stateChangeGuard.isCurrent(generation)) return;
    _onStateChanged?.call();
  }

  /// Whether the mutation has not been executed yet.
  bool get isIdle => _state.isIdle;

  /// Whether the mutation is currently executing.
  bool get isLoading => _state.isLoading;

  /// Whether the mutation completed successfully.
  bool get isSuccess => _state.isSuccess;

  /// Whether the mutation failed.
  bool get isError => _state.isError;

  /// Returns the result from the current [MutationSuccess] state.
  ///
  /// Use this getter only when the mutation is known to be in a
  /// [MutationSuccess] state.
  ///
  /// Throws a [StateError] if the current mutation state does not contain
  /// a successful result.
  ///
  /// Use [dataOrNull] when the mutation may be in another state and the
  /// result may not be available.
  ///
  /// ```dart
  /// if (mutation.isSuccess) {
  ///   final result = mutation.data;
  /// }
  /// ```
  T get data {
    final state = _state;

    if (state is MutationSuccess<T>) {
      return state.data;
    }

    throw StateError(
      'Data is only available when the current state is a MutationSuccess. '
      'Current state: ${state.runtimeType}.',
    );
  }

  /// Returns the result when the current state is [MutationSuccess],
  /// otherwise `null`.
  T? get dataOrNull {
    final state = _state;

    if (state is MutationSuccess<T>) {
      return state.data;
    }

    return null;
  }

  VoidCallback? _onFirstListenerAdded;
  VoidCallback? _onLastListenerRemoved;
  VoidCallback? _onStateChanged;
  VoidCallback? _onExecutionCompleted;
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

  /// Internal: called by MutationGroup when an execution completes.
  void _setOnExecutionCompleted(VoidCallback? callback) {
    _onExecutionCompleted = callback;
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

  /// Disposes this mutation and releases its resources.
  ///
  /// Active executions whose outcomes have not yet been committed are
  /// invalidated, and queued executions are completed with
  /// [MutationIgnored] using [MutationIgnoreReason.disposed].
  ///
  /// Disposing does not cancel already-running asynchronous actions.
  /// Their eventual outcomes are ignored if they have not been committed.
  ///
  /// Already committed outcomes and callbacks that have already started
  /// are not retroactively invalidated. Their callbacks are allowed to finish,
  /// and their returned futures can still complete normally.
  ///
  /// After disposal, the mutation no longer publishes state changes.
  /// This method is safe to call multiple times.
  @override
  void dispose() {
    if (!mounted) return;

    _stateChangeGuard.invalidate();

    // Stop accepting work and mark active, uncommitted executions as disposed.
    // Their underlying actions are not cancellable; they complete as ignored.
    final queuedExecutions = _concurrencyHandler.dispose();

    final onDisposed = _onDisposed;
    _onFirstListenerAdded = null;
    _onLastListenerRemoved = null;
    _onStateChanged = null;
    _onExecutionCompleted = null;
    _onDisposed = null;

    onDisposed?.call();

    // Queued executions never started, so they can be completed immediately.
    for (final execution in queuedExecutions) {
      _completeIgnored(execution, MutationIgnoreReason.disposed);
    }

    super.dispose();
  }
}
