part of '../mutation.dart';

/// Represents a single invocation of [Mutation.run].
///
/// Each execution owns its action, callbacks, completion Future,
/// and invalidation reason.
class _MutationExecution<T> {
  _MutationExecution({required this.action, this.onSuccess, this.onError});

  final MutationActionCallback<T> action;
  final MutationSuccessCallback<T>? onSuccess;
  final MutationErrorCallback? onError;

  final Completer<MutationResult<T>> completer = Completer<MutationResult<T>>();

  /// The reason this execution was invalidated, if applicable.
  MutationIgnoreReason? ignoreReason;

  /// Whether this execution's outcome has been accepted and committed.
  ///
  /// A committed outcome cannot be retroactively superseded or invalidated.
  bool outcomeCommitted = false;
}
