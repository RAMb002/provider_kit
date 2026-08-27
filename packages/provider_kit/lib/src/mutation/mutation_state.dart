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
