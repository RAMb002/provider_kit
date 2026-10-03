part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state.aggregation}
/// ### State priority
///
/// The widget evaluates the states of the watched providers using the
/// following priority:
///
/// 1. **Error** — when any provider is in [ErrorState].
/// 2. **Initial** — when no error exists and any provider is in
///    [InitialState].
/// 3. **Loading** — when no error or initial state exists and any provider is
///    in [LoadingState].
/// 4. **Empty** — when no error, initial, or loading state exists and any
///    provider is in [EmptyState].
/// 5. **Data** — when none of the above conditions applies.
///
/// ### Empty state
///
/// A provider can use [EmptyState] when its data represents an empty
/// [Iterable] result.
///
/// If any watched provider is in [EmptyState], the combined state is
/// [EmptyState]. This guarantees that the data callback is only invoked when
/// all watched providers are in [DataState].
///
/// ### Multiple providers in the same state
///
/// When multiple providers are in the same state, the first matching provider
/// determines the details passed to the corresponding callback. Providers are
/// considered in the order they are accessed through `.watch`.
///
/// This applies to [ErrorState], [LoadingState], and [EmptyState].
///
/// For example, when two providers are loading, the loading message from the
/// first provider is used. Likewise, the first error or empty state determines
/// the details passed to its callback.
///
/// When the retry callback is invoked, it retries every watched provider
/// that is currently in [ErrorState] and has a retry operation available.
///
/// ### Loading progress
///
/// Loading progress is calculated from the available progress values. Loading
/// states without progress do not contribute to the average.
///
/// ### Combined Data state
///
/// The combined value returned by [providers] is passed unchanged to
/// corresponding data callback, preserving its original type.
///
/// ### Change detection
///
/// Multi View State widgets do not react to every notification from a watched
/// provider. A listener or builder is processed only when the combined ViewState
/// exposed by the widget changes.
///
/// ProviderKit compares the previous and current combined state according to
/// the aggregated state:
///
/// - **Error** — a change is detected when the error information from the
///   first provider in [providers] that is in [ErrorState] changes, or when
///   the set of providers with an available retry operation changes.
/// - **Initial** — a change is detected when the combined state enters
///   [InitialState]. Repeated [InitialState] values do not trigger the listener
///   or builder.
/// - **Loading** — a change is detected when the loading message from the
///   first provider in [providers] that is in [LoadingState] changes, or when
///   the aggregated loading progress changes.
/// - **Empty** — a change is detected when the message from the first provider
///   in [providers] that is in [EmptyState] changes.
/// - **Data** — a change is detected when the combined value returned by
///   [providers] changes.
///
/// Providers are considered in the order in which they are accessed through
/// `.watch`.
///
/// A notification from a provider does not trigger the listener or builder
/// when it does not change the combined state exposed by Multi View State.
///
/// For example, when multiple providers are in [LoadingState], changing the
/// message of a later loading provider does not trigger the listener or builder
/// if the first loading provider's message and the aggregated loading progress
/// remain unchanged.
///
/// After ProviderKit detects a combined-state change, [listenWhen] and
/// [rebuildWhen] are evaluated as additional user-defined filters.
/// {@endtemplate}

abstract class _MultiViewStateUtils {
  static _MultiViewStateAggregate _aggregate(
    List<ViewStateNotifier<dynamic>> providers,
  ) {
    ErrorState<dynamic>? firstErrorState;
    LoadingState<dynamic>? firstLoadingState;
    EmptyState<dynamic>? firstEmptyState;

    final List<ViewStateNotifier<dynamic>> retryableProviders =
        <ViewStateNotifier<dynamic>>[];

    bool hasInitialState = false;

    double loadingProgressTotal = 0.0;
    int loadingProgressCount = 0;

    for (final ViewStateNotifier<dynamic> provider in providers) {
      final ViewState<dynamic> state = provider.state;

      if (state is ErrorState<dynamic>) {
        firstErrorState ??= state;

        if (state.onRetry != null || provider is AsyncViewStateNotifier) {
          retryableProviders.add(provider);
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
        continue;
      }
    }

    if (firstErrorState != null) {
      return _MultiViewStateAggregate.error(
        errorInfo: firstErrorState.errorInfo,
        error: firstErrorState.error,
        stackTrace: firstErrorState.stackTrace,
        retryableProviders: List.unmodifiable(retryableProviders),
      );
    }

    if (hasInitialState) {
      return const _MultiViewStateAggregate.initial();
    }

    if (firstLoadingState != null) {
      final double? loadingProgress = loadingProgressCount == 0
          ? null
          : loadingProgressTotal / loadingProgressCount;

      return _MultiViewStateAggregate.loading(
        message: firstLoadingState.message,
        progress: loadingProgress,
      );
    }

    if (firstEmptyState != null) {
      return _MultiViewStateAggregate.empty(message: firstEmptyState.message);
    }

    return const _MultiViewStateAggregate.data();
  }

  static VoidCallback? _createRetryCallback(
    List<ViewStateNotifier<dynamic>> providers,
  ) {
    final bool hasRetry = providers.any((provider) {
      final ViewState<dynamic> state = provider.state;

      return state is ErrorState<dynamic> &&
          (state.onRetry != null || provider is AsyncViewStateNotifier);
    });

    if (!hasRetry) {
      return null;
    }

    return () {
      for (final ViewStateNotifier<dynamic> provider in providers) {
        final ViewState<dynamic> state = provider.state;

        if (state is! ErrorState<dynamic>) {
          continue;
        }

        if (state.onRetry != null) {
          state.onRetry!.call();
        } else if (provider is AsyncViewStateNotifier) {
          provider.refresh();
        }
      }
    };
  }

  static void handleListener<T>(
    T state,
    _MultiViewStateAggregate aggregate,
    ErrorStateListener? errorStateListener,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    DataStateListener<T>? dataStateListener,
  ) {
    switch (aggregate.status) {
      case _MultiViewStateStatus.error:
        final VoidCallback? onRetry = _createRetryCallback(
          aggregate.retryableProviders ?? const [],
        );

        errorStateListener?.call(
          aggregate.errorInfo!,
          aggregate.error!,
          aggregate.stackTrace!,
          onRetry,
        );

      case _MultiViewStateStatus.initial:
        initialStateListener?.call();

      case _MultiViewStateStatus.loading:
        loadingStateListener?.call(
          aggregate.loadingMessage,
          aggregate.loadingProgress,
        );

      case _MultiViewStateStatus.empty:
        emptyStateListener?.call(aggregate.emptyMessage);

      case _MultiViewStateStatus.data:
        dataStateListener?.call(state);
    }
  }

  static Widget handleBuilder<T>(
    T state,
    _MultiViewStateAggregate aggregate,
    ErrorStateBuilder? errorBuilder,
    BuildContext context,
    bool isSliver,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    DataStateBuilder<T> dataBuilder,
  ) {
    switch (aggregate.status) {
      case _MultiViewStateStatus.error:
        return _buildErrorWidget(aggregate, errorBuilder, context, isSliver);

      case _MultiViewStateStatus.initial:
        return ViewStateWidgetUtils.buildInitialWidget(
          context,
          initialBuilder,
          isSliver,
        );

      case _MultiViewStateStatus.loading:
        return ViewStateWidgetUtils.buildLoadingWidget(
          context,
          loadingBuilder,
          aggregate.loadingMessage,
          aggregate.loadingProgress,
          isSliver,
        );

      case _MultiViewStateStatus.empty:
        return ViewStateWidgetUtils.buildEmptyWidget(
          context,
          emptyBuilder,
          aggregate.emptyMessage,
          isSliver,
        );

      case _MultiViewStateStatus.data:
        return dataBuilder(state);
    }
  }

  static Widget _buildErrorWidget(
    _MultiViewStateAggregate aggregate,
    ErrorStateBuilder? errorBuilder,
    BuildContext context,
    bool isSliver,
  ) {
    final VoidCallback? onRetry = _createRetryCallback(
      aggregate.retryableProviders ?? const [],
    );

    return errorBuilder?.call(
          aggregate.errorInfo!,
          aggregate.error!,
          aggregate.stackTrace!,
          onRetry,
          isSliver,
        ) ??
        context.errorStateWidget(
          aggregate.errorInfo!,
          aggregate.error!,
          aggregate.stackTrace!,
          onRetry,
          isSliver,
        );
  }
}
