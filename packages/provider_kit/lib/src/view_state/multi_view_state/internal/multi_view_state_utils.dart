part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state.aggregation}
/// ### State priority
///
/// The widget evaluates the states of the watched view-state notifiers using
/// the following priority:
///
/// 1. **Error** — when any view-state notifier is in [ErrorState].
/// 2. **Initial** — when no error exists and any view-state notifier is in
///    [InitialState].
/// 3. **Loading** — when no error or initial state exists and any view-state
///    notifier is in [LoadingState].
/// 4. **Empty** — when no error, initial, or loading state exists and any
///    view-state notifier is in [EmptyState].
/// 5. **Data** — when none of the above conditions applies.
///
/// ### Empty state
///
/// A view-state notifier can expose [EmptyState] when its data represents an
/// empty [Iterable] result.
///
/// If any watched view-state notifier is in [EmptyState], the combined state
/// is [EmptyState]. This guarantees that the data callback is only invoked when
/// all watched view-state notifiers are in [DataState].
///
/// ### Multiple view-state notifiers in the same state
///
/// When multiple view-state notifiers are in the same view-state, the first
/// matching notifier determines the details passed to the corresponding
/// callback. Notifiers are considered in the order they are accessed through
/// `.watch`.
///
/// This applies to [ErrorState], [LoadingState], and [EmptyState].
///
/// For example, when multiple view-state notifiers are loading, the loading
/// message from the first notifier is used. Likewise, the first notifier in
/// the error or empty state determines the details passed to its callback.
///
/// When the retry callback is invoked, it retries every watched view-state
/// notifier that is currently in [ErrorState] and has a retry operation
/// available.
///
/// ### Loading progress
///
/// Loading progress is calculated from the available progress values. Loading
/// states without progress do not contribute to the average.
///
/// ### Combined Data state
///
/// The data callback is invoked only when all watched view-state notifiers are in
/// [DataState]. The combined value returned by [listenables] is passed unchanged
/// to the callback, preserving its original type. Each value is a [ViewState],
/// and its `.data` getter provides the underlying data.
///
/// ### Change detection
///
/// Multi View State widgets do not react to every notification from a watched
/// view-state notifier. A listener or builder is processed only when the
/// combined ViewState exposed by the widget changes.
///
/// ProviderKit compares the previous and current combined state according to
/// the aggregated state:
///
/// - **Error** — a change is detected when the error information from the
///   first view-state notifier accessed through [listenables] that is in
///   [ErrorState] changes, or when the set of view-state notifiers with an
///   available retry operation changes.
/// - **Initial** — a change is detected when the combined state enters
///   [InitialState]. Repeated [InitialState] values do not trigger the listener
///   or builder.
/// - **Loading** — a change is detected when the loading message from the
///   first view-state notifier accessed through [listenables] that is in [LoadingState] changes, or when
///   the aggregated loading progress changes.
/// - **Empty** — a change is detected when the empty-state message changes
///   or when the ordered list of notifiers with an available refresh
///   operation changes.
/// - **Data** — a change is detected when the combined value returned by
///   [listenables] changes.
///
/// View-state notifiers are considered in the order in which they are accessed
/// through `.watch`.
///
/// A notification from a view-state notifier does not trigger the listener or
/// builder when it does not change the combined state exposed by Multi View
/// State.
///
/// For example, when multiple view-state notifiers are in [LoadingState], changing the
/// message of a later loading notifier does not trigger the listener or builder
/// if the first loading notifier's message and the aggregated loading progress
/// remain unchanged.
///
/// After ProviderKit detects a combined-state change, [listenWhen] and
/// [rebuildWhen] are evaluated as additional user-defined filters.
/// {@endtemplate}

@internal
final class MultiViewStateUtils {
  static MultiViewStateAggregate _aggregate(
    List<ViewStateNotifier<dynamic>> listenables,
  ) {
    ErrorState<dynamic>? firstErrorState;
    LoadingState<dynamic>? firstLoadingState;
    EmptyState<dynamic>? firstEmptyState;

    final List<ViewStateNotifier<dynamic>> retryableListenables =
        <ViewStateNotifier<dynamic>>[];
    final List<ViewStateNotifier<dynamic>> refreshableListenables =
        <ViewStateNotifier<dynamic>>[];

    bool hasInitialState = false;

    double loadingProgressTotal = 0.0;
    int loadingProgressCount = 0;

    for (final ViewStateNotifier<dynamic> listenable in listenables) {
      final ViewState<dynamic> state = listenable.state;

      if (state is ErrorState<dynamic>) {
        firstErrorState ??= state;

        if (state.onRetry != null ||
            listenable is AsyncViewStateNotifier<dynamic>) {
          retryableListenables.add(listenable);
        }
        continue;
      }

      if (state is InitialState<dynamic>) {
        hasInitialState = true;
        continue;
      }

      if (state is LoadingState<dynamic>) {
        firstLoadingState ??= state;

        final double? progress = state.progress;

        if (progress != null) {
          loadingProgressTotal += progress;
          loadingProgressCount++;
        }

        continue;
      }

      if (state is EmptyState<dynamic>) {
        firstEmptyState ??= state;

        if (state.onRefresh != null ||
            listenable is AsyncViewStateNotifier<dynamic>) {
          refreshableListenables.add(listenable);
        }

        continue;
      }
    }

    if (firstErrorState != null) {
      return MultiViewStateAggregate.error(
        errorInfo: firstErrorState.errorInfo,
        error: firstErrorState.error,
        stackTrace: firstErrorState.stackTrace,
        retryableListenables: List.unmodifiable(retryableListenables),
      );
    }

    if (hasInitialState) {
      return const MultiViewStateAggregate.initial();
    }

    if (firstLoadingState != null) {
      final double? loadingProgress = loadingProgressCount == 0
          ? null
          : loadingProgressTotal / loadingProgressCount;

      return MultiViewStateAggregate.loading(
        message: firstLoadingState.message,
        progress: loadingProgress,
      );
    }

    if (firstEmptyState != null) {
      return MultiViewStateAggregate.empty(
        message: firstEmptyState.message,
        refreshableListenables: List.unmodifiable(refreshableListenables),
      );
    }

    return const MultiViewStateAggregate.data();
  }

  static VoidCallback? _createRetryCallback(
    List<ViewStateNotifier<dynamic>> listenables,
  ) {
    return _createStateActionCallback(
      listenables: listenables,
      matchesState: (state) => state is ErrorState<dynamic>,
      getStateCallback: (state) {
        return state is ErrorState<dynamic> ? state.onRetry : null;
      },
      callbackErrorMessage:
          'While invoking ErrorState.onRetry in the MultiViewState retry operation.',
    );
  }

  static VoidCallback? _createRefreshCallback(
    List<ViewStateNotifier<dynamic>> listenables,
  ) {
    return _createStateActionCallback(
      listenables: listenables,
      matchesState: (state) => state is EmptyState<dynamic>,
      getStateCallback: (state) {
        return state is EmptyState<dynamic> ? state.onRefresh : null;
      },
      callbackErrorMessage:
          'While invoking EmptyState.onRefresh in the MultiViewState refresh operation.',
    );
  }

  static VoidCallback? _createStateActionCallback({
    required List<ViewStateNotifier<dynamic>> listenables,
    required bool Function(ViewState<dynamic> state) matchesState,
    required VoidCallback? Function(ViewState<dynamic> state) getStateCallback,
    required String callbackErrorMessage,
  }) {
    bool canPerformAction(ViewStateNotifier<dynamic> listenable) {
      final state = listenable.state;

      return matchesState(state) &&
          (getStateCallback(state) != null ||
              listenable is AsyncViewStateNotifier<dynamic>);
    }

    if (!listenables.any(canPerformAction)) {
      return null;
    }

    return () {
      for (final ViewStateNotifier<dynamic> listenable in listenables) {
        final state = listenable.state;

        if (!matchesState(state)) {
          continue;
        }

        final callback = getStateCallback(state);

        if (callback != null) {
          try {
            callback();
          } catch (error, stackTrace) {
            reportErrorToFlutter(
              error,
              stackTrace,
              message:
                  '$callbackErrorMessage '
                  'Notifier: ${listenable.runtimeType}; '
                  'state: ${state.runtimeType}.',
            );
          }
        } else if (listenable is AsyncViewStateNotifier<dynamic>) {
          listenable.refresh().ignore();
        }
      }
    };
  }

  static void handleListener<T>(
    BuildContext context,
    T state,
    MultiViewStateAggregate aggregate,
    ErrorStateListener? errorStateListener,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    DataStateListener<T>? dataStateListener,
  ) {
    switch (aggregate.status) {
      case MultiViewStateStatus.error:
        final VoidCallback? onRetry = _createRetryCallback(
          aggregate.retryableListenables ?? const [],
        );

        final errorDetails = ErrorStateDetails(
          errorInfo: ViewStateWidgetUtils.resolveErrorInfo(
            context,
            aggregate.errorInfo!,
          ),
          error: aggregate.error!,
          stackTrace: aggregate.stackTrace!,
          onRetry: onRetry,
        );

        errorStateListener?.call(context, errorDetails);

      case MultiViewStateStatus.initial:
        initialStateListener?.call(context);

      case MultiViewStateStatus.loading:
        final loadingDetails = LoadingStateDetails(
          message: context.resolveViewStateMessage(aggregate.loadingMessage),
          progress: aggregate.loadingProgress,
        );
        loadingStateListener?.call(context, loadingDetails);

      case MultiViewStateStatus.empty:
        final onRefresh = _createRefreshCallback(
          aggregate.refreshableListenables ?? const [],
        );

        final emptyStateDetails = EmptyStateDetails(
          message: context.resolveViewStateMessage(aggregate.emptyMessage),
          onRefresh: onRefresh,
        );

        emptyStateListener?.call(context, emptyStateDetails);

      case MultiViewStateStatus.data:
        dataStateListener?.call(context, state);
    }
  }

  static Widget handleBuilder<T>(
    T state,
    MultiViewStateAggregate aggregate,
    ErrorStateBuilder? errorBuilder,
    BuildContext context,
    bool isSliver,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    DataStateBuilder<T> dataBuilder,
    Widget? child,
  ) {
    switch (aggregate.status) {
      case MultiViewStateStatus.error:
        return _buildErrorWidget(aggregate, errorBuilder, context, isSliver);

      case MultiViewStateStatus.initial:
        return ViewStateWidgetUtils.buildInitialWidget(
          context,
          initialBuilder,
          isSliver,
        );

      case MultiViewStateStatus.loading:
        return ViewStateWidgetUtils.buildLoadingWidget(
          context,
          loadingBuilder,
          aggregate.loadingMessage,
          aggregate.loadingProgress,
          isSliver,
        );

      case MultiViewStateStatus.empty:
        return _buildEmptyWidget(aggregate, emptyBuilder, context, isSliver);

      case MultiViewStateStatus.data:
        return dataBuilder(context, state, child);
    }
  }

  static Widget _buildEmptyWidget(
    MultiViewStateAggregate aggregate,
    EmptyStateBuilder? emptyBuilder,
    BuildContext context,
    bool isSliver,
  ) {
    final VoidCallback? onRefresh = _createRefreshCallback(
      aggregate.refreshableListenables ?? const [],
    );

    final details = EmptyStateDetails(
      message: context.resolveViewStateMessage(aggregate.emptyMessage),
      onRefresh: onRefresh,
    );

    return emptyBuilder?.call(context, details) ??
        context.emptyStateWidget(context, details, isSliver);
  }

  static Widget _buildErrorWidget(
    MultiViewStateAggregate aggregate,
    ErrorStateBuilder? errorBuilder,
    BuildContext context,
    bool isSliver,
  ) {
    final VoidCallback? onRetry = _createRetryCallback(
      aggregate.retryableListenables ?? const [],
    );

    final details = ErrorStateDetails(
      errorInfo: ViewStateWidgetUtils.resolveErrorInfo(
        context,
        aggregate.errorInfo!,
      ),
      error: aggregate.error!,
      stackTrace: aggregate.stackTrace!,
      onRetry: onRetry,
    );

    return errorBuilder?.call(context, details) ??
        context.errorStateWidget(context, details, isSliver);
  }
}
