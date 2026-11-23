part of 'mutation.dart';

/// {@template provider_kit.mutation_result}
/// Represents the outcome of a single [Mutation.run] invocation.
///
/// Unlike [MutationState], which represents the current observable state of
/// a mutation, [MutationResult] describes what happened during an individual
/// execution.
///
/// Each call to [Mutation.run] produces one of the following outcomes:
///
/// - [MutationSucceeded] when the action completes successfully. It contains
///   the value returned by the action.
/// - [MutationErrored] when the action fails. It contains the original error,
///   stack trace, and mapped [ErrorInfo]. Action errors are returned rather
///   than rethrown.
/// - [MutationIgnored] when the execution is rejected or invalidated before
///   its outcome is committed. It contains the [MutationIgnoreReason].
///
/// An execution can be ignored when it is rejected by
/// [MutationConcurrency.ignoreIfBusy], superseded by
/// [MutationConcurrency.latestOnly], or invalidated by [Mutation.reset] or
/// disposal.
///
/// ### Basic usage
///
/// The result can be handled using [when], which requires handling every
/// possible outcome:
///
/// ```dart
/// final result = await createTodo.run(
///   () => repository.create(todo),
/// );
///
/// result.when(
///   succeeded: (data) {
///     print('Created: $data');
///   },
///   errored: (errorInfo, error, stackTrace) {
///     print(errorInfo.message);
///   },
///   ignored: (reason) {
///     print('Execution ignored: $reason');
///   },
/// );
/// ```
///
/// ### Handling specific outcomes
///
/// You can use [maybeWhen] or [whenOrNull] when you only need to handle
/// specific outcomes. [maybeWhen] provides an [orElse] fallback, while
/// [whenOrNull] returns `null` when no matching callback is provided.
///
/// Use [map], [maybeMap], and [mapOrNull] when you prefer to receive the
/// complete result object in each callback instead of its individual values.
///
/// ### Results and mutation state
///
/// A [MutationResult] belongs to the individual invocation that produced it.
/// It does not represent or track the mutation's current state.
///
/// This distinction is especially important when multiple executions overlap:
/// each invocation receives its own result, while the mutation exposes a
/// single current [MutationState].
///
/// Use [MutationState] with [StateBuilder] or [StateListener] when you need
/// to react to changes in the mutation's current state.
///
/// Use [MutationResult] when you need to handle the outcome of a specific
/// execution, such as displaying a message, navigating, or deciding whether
/// to perform another operation.
///
///
/// See also:
///
/// - [Mutation], for managing asynchronous operations.
/// - [Mutation.run], for executing an operation and receiving its result.
/// - [MutationState], for representing the current observable state.
/// - [MutationIgnoreReason], for understanding why an execution was ignored.
/// {@endtemplate}
@immutable
sealed class MutationResult<T> {
  const MutationResult._();

  /// Executes the callback corresponding to this execution result.
  ///
  /// All result callbacks are required, so every possible outcome must be
  /// handled.
  ///
  /// Use [when] when you want to handle every possible execution outcome.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = result.when(
  ///   succeeded: (data) => 'Created: $data',
  ///   errored: (errorInfo, error, stackTrace) => errorInfo.message,
  ///   ignored: (reason) => 'Ignored: $reason',
  /// );
  /// ```
  R when<R>({
    required R Function(T data) succeeded,
    required R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
    )
    errored,
    required R Function(MutationIgnoreReason reason) ignored,
  }) {
    final result = this;

    return switch (result) {
      MutationSucceeded<T>() => succeeded(result.data),
      MutationErrored<T>() => errored(
        result.errorInfo,
        result.error,
        result.stackTrace,
      ),
      MutationIgnored<T>() => ignored(result.reason),
    };
  }

  /// Executes the callback corresponding to this execution result.
  ///
  /// Only the callbacks you provide are invoked. If the result does not have
  /// a matching callback, [orElse] is invoked instead.
  ///
  /// Use [maybeWhen] when you want to handle specific outcomes while
  /// providing a fallback through [orElse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = result.maybeWhen(
  ///   succeeded: (data) => 'Created: $data',
  ///   errored: (errorInfo, error, stackTrace) => errorInfo.message,
  ///   orElse: () => 'No result available',
  /// );
  /// ```
  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T data)? succeeded,
    R Function(ErrorInfo errorInfo, Object error, StackTrace stackTrace)?
    errored,
    R Function(MutationIgnoreReason reason)? ignored,
  }) {
    final result = this;

    return switch (result) {
      MutationSucceeded<T>() =>
        succeeded != null ? succeeded(result.data) : orElse(),
      MutationErrored<T>() =>
        errored != null
            ? errored(result.errorInfo, result.error, result.stackTrace)
            : orElse(),
      MutationIgnored<T>() =>
        ignored != null ? ignored(result.reason) : orElse(),
    };
  }

  /// Executes the callback corresponding to this execution result.
  ///
  /// Only the callbacks you provide are invoked. If the result does not have
  /// a matching callback, this method returns `null`.
  ///
  /// Use [whenOrNull] when you want to handle specific outcomes without
  /// providing fallback behavior for the remaining outcomes.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = result.whenOrNull(
  ///   succeeded: (data) => 'Created: $data',
  ///   errored: (errorInfo, error, stackTrace) => errorInfo.message,
  /// );
  /// ```
  ///
  /// For outcomes without a matching callback, [whenOrNull] returns `null`.
  R? whenOrNull<R extends Object?>({
    R Function(T data)? succeeded,
    R Function(ErrorInfo errorInfo, Object error, StackTrace stackTrace)?
    errored,
    R Function(MutationIgnoreReason reason)? ignored,
  }) {
    final result = this;

    return switch (result) {
      MutationSucceeded<T>() => succeeded?.call(result.data),
      MutationErrored<T>() => errored?.call(
        result.errorInfo,
        result.error,
        result.stackTrace,
      ),
      MutationIgnored<T>() => ignored?.call(result.reason),
    };
  }

  /// Invokes the callback corresponding to this execution result.
  ///
  /// All result callbacks are required, so every possible outcome must be
  /// handled.
  ///
  /// The callbacks receive the complete result object rather than individual
  /// result values.
  ///
  /// Use [map] when you prefer to work with the complete result object.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = result.map(
  ///   succeeded: (result) => 'Created: ${result.data}',
  ///   errored: (result) => result.errorInfo.message,
  ///   ignored: (result) => 'Ignored: ${result.reason}',
  /// );
  /// ```
  R map<R>({
    required R Function(MutationSucceeded<T> succeeded) succeeded,
    required R Function(MutationErrored<T> errored) errored,
    required R Function(MutationIgnored<T> ignored) ignored,
  }) {
    final result = this;

    return switch (result) {
      MutationSucceeded<T>() => succeeded(result),
      MutationErrored<T>() => errored(result),
      MutationIgnored<T>() => ignored(result),
    };
  }

  /// Maps this execution result to a corresponding callback.
  ///
  /// Only the callbacks you provide are invoked. If the result does not have
  /// a matching callback, [orElse] is invoked instead.
  ///
  /// The callbacks receive the complete result object rather than individual
  /// result values.
  ///
  /// Use [maybeMap] when you want to handle specific outcomes while providing
  /// a fallback through [orElse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = result.maybeMap(
  ///   succeeded: (result) => 'Created: ${result.data}',
  ///   errored: (result) => result.errorInfo.message,
  ///   orElse: () => 'No result available',
  /// );
  /// ```
  R maybeMap<R>({
    required R Function() orElse,
    R Function(MutationSucceeded<T> succeeded)? succeeded,
    R Function(MutationErrored<T> errored)? errored,
    R Function(MutationIgnored<T> ignored)? ignored,
  }) {
    final result = this;

    return switch (result) {
      MutationSucceeded<T>() =>
        succeeded != null ? succeeded(result) : orElse(),
      MutationErrored<T>() => errored != null ? errored(result) : orElse(),
      MutationIgnored<T>() => ignored != null ? ignored(result) : orElse(),
    };
  }

  /// Maps this execution result to a corresponding callback.
  ///
  /// Only the callbacks you provide are invoked. If the result does not have
  /// a matching callback, this method returns `null`.
  ///
  /// The callbacks receive the complete result object rather than individual
  /// result values.
  ///
  /// Use [mapOrNull] when you want to handle specific outcomes without
  /// providing fallback behavior for the remaining outcomes.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = result.mapOrNull(
  ///   errored: (result) => result.errorInfo.message,
  /// );
  /// ```
  ///
  /// For outcomes without a matching callback, [mapOrNull] returns `null`.
  R? mapOrNull<R extends Object?>({
    R Function(MutationSucceeded<T> succeeded)? succeeded,
    R Function(MutationErrored<T> errored)? errored,
    R Function(MutationIgnored<T> ignored)? ignored,
  }) {
    final result = this;

    return switch (result) {
      MutationSucceeded<T>() => succeeded?.call(result),
      MutationErrored<T>() => errored?.call(result),
      MutationIgnored<T>() => ignored?.call(result),
    };
  }

  /// Whether this execution completed successfully.
  bool get isSucceeded => this is MutationSucceeded<T>;

  /// Whether this execution errored.
  bool get isErrored => this is MutationErrored<T>;

  /// Whether this execution was ignored.
  bool get isIgnored => this is MutationIgnored<T>;
}

/// Represents an execution that completed successfully.
///
/// The value returned by the operation is available through [data].
///
/// This result is produced when the execution completes successfully and its
/// outcome is accepted by the mutation's concurrency policy.
final class MutationSucceeded<T> extends MutationResult<T> {
  const MutationSucceeded._(this.data) : super._();

  /// The value returned by the successful operation.
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutationSucceeded<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'MutationSucceeded { data: $data }';
}

/// Represents an execution that errored.
///
/// The original error and its associated [StackTrace] are available through
/// [error] and [stackTrace].
///
/// The mapped error information is available through [errorInfo].
///
/// Unlike [MutationError], which represents the current observable error
/// state, [MutationErrored] represents the failure of an individual execution.
final class MutationErrored<T> extends MutationResult<T> {
  const MutationErrored._(this.error, this.stackTrace, this.errorInfo)
    : super._();

  /// {@macro provider_kit.error_info_field}
  final ErrorInfo errorInfo;

  /// The original error thrown by the operation.
  final Object error;

  /// The stack trace associated with [error].
  final StackTrace stackTrace;

  /// The message provided by [errorInfo].
  String get message => errorInfo.message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutationErrored<T> &&
          runtimeType == other.runtimeType &&
          other.errorInfo == errorInfo &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(runtimeType, errorInfo, error, stackTrace);

  @override
  String toString() =>
      'MutationErrored { errorInfo: $errorInfo, error: $error, '
      'stackTrace: $stackTrace }';
}

/// Represents an execution whose outcome was ignored.
///
/// An execution can be ignored for several reasons:
///
/// - It was rejected because another execution was already running.
/// - It was superseded by a newer execution.
/// - It was invalidated by [Mutation.reset].
/// - Its mutation was disposed before the execution could be accepted.
///
/// An ignored execution does not update the mutation's state or invoke its
/// success and error callbacks.
///
/// The reason for ignoring the execution is available through [reason].
final class MutationIgnored<T> extends MutationResult<T> {
  const MutationIgnored._(this.reason) : super._();

  /// Why the execution was ignored.
  final MutationIgnoreReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutationIgnored<T> &&
          runtimeType == other.runtimeType &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() => 'MutationIgnored { reason: $reason }';
}

/// Describes why a mutation execution was ignored.
enum MutationIgnoreReason {
  /// The execution was skipped because another execution was already active.
  ///
  /// This occurs with [MutationConcurrency.ignoreIfBusy].
  /// The operation never starts.
  busy,

  /// The execution was replaced by a newer execution.
  ///
  /// This occurs with [MutationConcurrency.latestOnly].
  /// The older operation may continue running, but its outcome is no longer
  /// accepted and cannot update the mutation state or invoke callbacks.
  replaced,

  /// The execution was invalidated by calling [Mutation.reset].
  ///
  /// A running operation is not necessarily cancelled, but its eventual
  /// outcome is ignored.
  reset,

  /// The execution was invalidated because its mutation was disposed.
  ///
  /// A running operation is not necessarily cancelled, but its eventual
  /// outcome is ignored.
  disposed,
}
