part of 'mutation.dart';

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
  /// Executes the callback corresponding to the current mutation state.
  ///
  /// All mutation state callbacks are required, so every possible state must be
  /// handled.
  ///
  /// Use [when] when you want to provide behavior for every mutation state.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final widget = state.when(
  ///   idle: () => const Text('Ready'),
  ///   loading: () => const CircularProgressIndicator(),
  ///   success: (data) => Text('Success: $data'),
  ///   error: (errorInfo, error, stackTrace) => Text(errorInfo.message),
  /// );
  /// ```
  /// {@endtemplate}
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
    ) error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle(),
      MutationLoading<T>() => loading(),
      MutationSuccess<T>() => success(state.data),
      MutationError<T>() =>
        error(state.errorInfo, state.error, state.stackTrace),
    };
  }

  /// {@template provider_kit.mutation_state.maybe_when}
  /// Executes the callback corresponding to the current mutation state.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, [orElse] is invoked instead.
  ///
  /// Use [maybeWhen] to handle only specific mutation states while providing
  /// a fallback through [orElse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final widget = state.maybeWhen(
  ///   success: (data) => Text('Success: $data'),
  ///   error: (errorInfo, error, stackTrace) => Text(errorInfo.message),
  ///   orElse: () => const Text('Waiting...'),
  /// );
  /// ```
  /// {@endtemplate}
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? success,
    R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
    )? error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle != null ? idle() : orElse(),
      MutationLoading<T>() => loading != null ? loading() : orElse(),
      MutationSuccess<T>() => success != null ? success(state.data) : orElse(),
      MutationError<T>() => error != null
          ? error(state.errorInfo, state.error, state.stackTrace)
          : orElse(),
    };
  }

  /// {@template provider_kit.mutation_state.when_or_null}
  /// Executes the callback corresponding to the current mutation state.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, this method returns `null`.
  ///
  /// Use [whenOrNull] when you want to handle only specific mutation states
  /// without providing fallback behavior for the remaining states.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = state.whenOrNull(
  ///   error: (errorInfo, error, stackTrace) => errorInfo.message,
  /// );
  /// ```
  ///
  /// For states without a matching callback, [whenOrNull] returns `null`.
  /// {@endtemplate}
  R? whenOrNull<R extends Object?>({
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? success,
    R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
    )? error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle?.call(),
      MutationLoading<T>() => loading?.call(),
      MutationSuccess<T>() => success?.call(state.data),
      MutationError<T>() => error?.call(
          state.errorInfo,
          state.error,
          state.stackTrace,
        ),
    };
  }

  /// {@template provider_kit.mutation_state.map}
  /// Invokes the callback corresponding to the current mutation state.
  ///
  /// All mutation state callbacks are required, so every possible state must be
  /// handled.
  ///
  /// The callbacks receive the complete mutation state object rather than
  /// individual state values.
  ///
  /// Use [map] when you prefer to work with the complete mutation state object.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final widget = state.map(
  ///   idle: (_) => const Text('Ready'),
  ///   loading: (_) => const CircularProgressIndicator(),
  ///   success: (state) => Text('Success: ${state.data}'),
  ///   error: (state) => Text(state.errorInfo.message),
  /// );
  /// ```
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

  /// {@template provider_kit.mutation_state.maybe_map}
  /// Maps the current mutation state to a corresponding callback.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, [orElse] is invoked instead.
  ///
  /// The callbacks receive the complete mutation state object rather than
  /// individual state values.
  ///
  /// Use [maybeMap] to handle only specific mutation states while providing
  /// a fallback through [orElse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final widget = state.maybeMap(
  ///   success: (state) => Text('Result: ${state.data}'),
  ///   error: (state) => Text(state.errorInfo.message),
  ///   orElse: () => const Text('Waiting...'),
  /// );
  /// ```
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

  /// {@template provider_kit.mutation_state.map_or_null}
  /// Maps the current mutation state to a corresponding callback.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, this method returns `null`.
  ///
  /// The callbacks receive the complete mutation state object rather than
  /// individual state values.
  ///
  /// Use [mapOrNull] to handle only specific mutation states without providing
  /// a fallback.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final message = state.mapOrNull(
  ///   error: (state) => state.errorInfo.message,
  /// );
  /// ```
  ///
  /// For states without a matching callback, [mapOrNull] returns `null`.
  /// {@endtemplate}
  R? mapOrNull<R extends Object?>({
    R Function(MutationIdle<T> idle)? idle,
    R Function(MutationLoading<T> loading)? loading,
    R Function(MutationSuccess<T> success)? success,
    R Function(MutationError<T> error)? error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle<T>() => idle?.call(state),
      MutationLoading<T>() => loading?.call(state),
      MutationSuccess<T>() => success?.call(state),
      MutationError<T>() => error?.call(state),
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

  @override
  String toString() => 'MutationSuccess { data: $data }';
}

/// {@template provider_kit.mutation_error}
/// Indicates that a mutation operation failed.
///
/// The error thrown by the operation is available through [error].
/// Its associated [StackTrace] is available through [stackTrace].
/// The mapped error information is available through [errorInfo].
/// {@endtemplate}
final class MutationError<T> extends MutationState<T> {
  MutationError._(
    this.error,
    this.stackTrace, {
    ErrorInfo? errorInfo,
  })  : errorInfo = errorInfo ??
            ProviderKit.resolveErrorInfo(
              error,
              stackTrace,
            ),
        super._();

  /// {@macro provider_kit.error_info_field}
  final ErrorInfo errorInfo;

  /// The error thrown during the mutation operation.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace stackTrace;

  /// The message provided by [errorInfo].
  String get message => errorInfo.message;

  @override
  bool operator ==(Object other) =>
      other is MutationError<T> &&
      runtimeType == other.runtimeType &&
      other.errorInfo == errorInfo &&
      other.error == error &&
      other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(errorInfo, error, stackTrace);

  @override
  String toString() => 'MutationError { errorInfo: $errorInfo, error: $error, '
      'stackTrace: $stackTrace }';
}
