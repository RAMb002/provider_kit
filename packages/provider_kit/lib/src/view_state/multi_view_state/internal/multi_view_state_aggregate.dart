part of '../../../state/multi_state/multi_state.dart';

@internal
enum MultiViewStateStatus { error, initial, loading, empty, data }

/// Internal snapshot of the values that are observable from the aggregated
/// Multi View State.
///
/// This is intentionally different from the individual listenable states.
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
    this.retryableListenables,
    this.loadingMessage,
    this.loadingProgress,
    this.emptyMessage,
    this.refreshableListenables,
  });

  const MultiViewStateAggregate.error({
    required ErrorInfo errorInfo,
    required Object error,
    required StackTrace stackTrace,
    required List<ViewStateNotifier<dynamic>> retryableListenables,
  }) : this._(
         status: MultiViewStateStatus.error,
         errorInfo: errorInfo,
         error: error,
         stackTrace: stackTrace,
         retryableListenables: retryableListenables,
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

  const MultiViewStateAggregate.empty({
    required String? message,
    required List<ViewStateNotifier<dynamic>> refreshableListenables,
  }) : this._(
         status: MultiViewStateStatus.empty,
         emptyMessage: message,
         refreshableListenables: refreshableListenables,
       );

  const MultiViewStateAggregate.data()
    : this._(status: MultiViewStateStatus.data);

  final MultiViewStateStatus status;

  // Error aggregate.
  final ErrorInfo? errorInfo;
  final Object? error;
  final StackTrace? stackTrace;

  /// Listenables that contribute to the combined retry operation.
  ///
  /// Listenable identity matters here because two different listenables may have
  /// identical state values but represent different retry operations.
  final List<ViewStateNotifier<dynamic>>? retryableListenables;

  // Loading aggregate.
  final String? loadingMessage;
  final double? loadingProgress;

  // Empty aggregate.
  final String? emptyMessage;

  /// Listenables that contribute to the combined refresh operation.
  ///
  /// Listenable identity matters because different listenables may expose
  /// identical empty-state messages but represent different refresh operations.
  final List<ViewStateNotifier<dynamic>>? refreshableListenables;

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

      MultiViewStateStatus.empty =>
        emptyMessage == other.emptyMessage &&
            _sameRefreshableListenables(other),

      MultiViewStateStatus.error =>
        errorInfo == other.errorInfo &&
            error == other.error &&
            stackTrace == other.stackTrace &&
            _sameRetryableListenables(other),
    };
  }

  bool _sameRetryableListenables(MultiViewStateAggregate other) {
    return _sameListenables(retryableListenables, other.retryableListenables);
  }

  bool _sameRefreshableListenables(MultiViewStateAggregate other) {
    return _sameListenables(
      refreshableListenables,
      other.refreshableListenables,
    );
  }

  static bool _sameListenables(
    List<ViewStateNotifier<dynamic>>? previous,
    List<ViewStateNotifier<dynamic>>? current,
  ) {
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
