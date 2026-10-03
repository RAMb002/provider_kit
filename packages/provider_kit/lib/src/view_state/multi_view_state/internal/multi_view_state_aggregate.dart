part of '../../../state/multi_state/multi_state.dart';

enum _MultiViewStateStatus { error, initial, loading, empty, data }

/// Internal snapshot of the values that are observable from the aggregated
/// Multi View State.
///
/// This is intentionally different from the individual provider states.
/// It contains only the information that affects the combined state exposed
/// by Multi View State widgets.
@immutable
final class _MultiViewStateAggregate {
  const _MultiViewStateAggregate._({
    required this.status,
    this.errorInfo,
    this.error,
    this.stackTrace,
    this.retryableProviders,
    this.loadingMessage,
    this.loadingProgress,
    this.emptyMessage,
  });

  const _MultiViewStateAggregate.error({
    required ErrorInfo errorInfo,
    required Object error,
    required StackTrace stackTrace,
    required List<ViewStateNotifier<dynamic>> retryableProviders,
  }) : this._(
         status: _MultiViewStateStatus.error,
         errorInfo: errorInfo,
         error: error,
         stackTrace: stackTrace,
         retryableProviders: retryableProviders,
       );

  const _MultiViewStateAggregate.initial()
    : this._(status: _MultiViewStateStatus.initial);

  const _MultiViewStateAggregate.loading({
    required String? message,
    required double? progress,
  }) : this._(
         status: _MultiViewStateStatus.loading,
         loadingMessage: message,
         loadingProgress: progress,
       );

  const _MultiViewStateAggregate.empty({required String? message})
    : this._(status: _MultiViewStateStatus.empty, emptyMessage: message);

  const _MultiViewStateAggregate.data()
    : this._(status: _MultiViewStateStatus.data);

  final _MultiViewStateStatus status;

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
  bool isSameAs(_MultiViewStateAggregate other) {
    if (status != other.status) {
      return false;
    }

    return switch (status) {
      _MultiViewStateStatus.initial || _MultiViewStateStatus.data => true,

      _MultiViewStateStatus.loading =>
        loadingMessage == other.loadingMessage &&
            loadingProgress == other.loadingProgress,

      _MultiViewStateStatus.empty => emptyMessage == other.emptyMessage,

      _MultiViewStateStatus.error =>
        errorInfo == other.errorInfo &&
            error == other.error &&
            stackTrace == other.stackTrace &&
            _sameRetryableProviders(other),
    };
  }

  bool _sameRetryableProviders(_MultiViewStateAggregate other) {
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
