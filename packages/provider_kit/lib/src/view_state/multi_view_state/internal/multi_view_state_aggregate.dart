part of '../../../state/multi_state/multi_state.dart';

@internal
enum MultiViewStateStatus { error, initial, loading, empty, data }

/// Internal snapshot of the values that are observable from the aggregated
/// Multi View State.
///
/// This is intentionally different from the individual provider states.
/// It contains only the information that affects the combined state exposed
/// by Multi View State widgets.
@internal
@immutable
final class MultiViewStateAggregate {
  const MultiViewStateAggregate._({
    required this.status,
    this.errorInfo,
    this.error,
    this.stackTrace,
    this.retryableProviders,
    this.loadingMessage,
    this.loadingProgress,
    this.emptyMessage,
  });

  const MultiViewStateAggregate.error({
    required ErrorInfo errorInfo,
    required Object error,
    required StackTrace stackTrace,
    required List<ViewStateNotifier<dynamic>> retryableProviders,
  }) : this._(
         status: MultiViewStateStatus.error,
         errorInfo: errorInfo,
         error: error,
         stackTrace: stackTrace,
         retryableProviders: retryableProviders,
       );

  const MultiViewStateAggregate.initial()
    : this._(status: MultiViewStateStatus.initial);

  const MultiViewStateAggregate.loading({
    required String? message,
    required double? progress,
  }) : this._(
         status: MultiViewStateStatus.loading,
         loadingMessage: message,
         loadingProgress: progress,
       );

  const MultiViewStateAggregate.empty({required String? message})
    : this._(status: MultiViewStateStatus.empty, emptyMessage: message);

  const MultiViewStateAggregate.data()
    : this._(status: MultiViewStateStatus.data);

  final MultiViewStateStatus status;

  // Error aggregate.
  final ErrorInfo? errorInfo;
  final Object? error;
  final StackTrace? stackTrace;

  /// Providers that contribute to the combined retry operation.
  ///
  /// Provider identity matters here because two different providers may have
  /// identical state values but represent different retry operations.
  final List<ViewStateNotifier<dynamic>>? retryableProviders;

  // Loading aggregate.
  final String? loadingMessage;
  final double? loadingProgress;

  // Empty aggregate.
  final String? emptyMessage;

  /// Returns whether this aggregate represents the same observable state as
  /// [other].
  ///
  /// The comparison intentionally checks only values that can affect the
  /// corresponding Multi View State callback or builder.
  bool isSameAs(MultiViewStateAggregate other) {
    if (status != other.status) {
      return false;
    }

    return switch (status) {
      MultiViewStateStatus.initial || MultiViewStateStatus.data => true,

      MultiViewStateStatus.loading =>
        loadingMessage == other.loadingMessage &&
            loadingProgress == other.loadingProgress,

      MultiViewStateStatus.empty => emptyMessage == other.emptyMessage,

      MultiViewStateStatus.error =>
        errorInfo == other.errorInfo &&
            error == other.error &&
            stackTrace == other.stackTrace &&
            _sameRetryableProviders(other),
    };
  }

  bool _sameRetryableProviders(MultiViewStateAggregate other) {
    final List<ViewStateNotifier<dynamic>>? previous = retryableProviders;
    final List<ViewStateNotifier<dynamic>>? current = other.retryableProviders;

    if (identical(previous, current)) {
      return true;
    }

    if (previous == null || current == null) {
      return false;
    }

    if (previous.length != current.length) {
      return false;
    }

    for (var index = 0; index < previous.length; index++) {
      if (!identical(previous[index], current[index])) {
        return false;
      }
    }

    return true;
  }
}
