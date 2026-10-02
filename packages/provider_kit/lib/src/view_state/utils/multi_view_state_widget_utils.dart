import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/view_state/notifiers/async_view_state_notifier.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/utils/view_state_widget_utils.dart';
import 'package:provider_kit/src/view_state/view_state_widgets_provider.dart';

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
/// that is currently in [ErrorState].
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
/// {@endtemplate}

@internal
abstract class MultiViewStateWidgetUtils {
  static _MultiViewStateAggregate _aggregate(
    List<ViewStateNotifier<dynamic>> providers,
  ) {
    ErrorState<dynamic>? firstErrorState;
    LoadingState<dynamic>? firstLoadingState;
    EmptyState<dynamic>? firstEmptyState;

    bool hasInitialState = false;

    double loadingProgressTotal = 0.0;
    int loadingProgressCount = 0;

    for (final ViewStateNotifier<dynamic> provider in providers) {
      final ViewState<dynamic> state = provider.state;

      if (state is ErrorState<dynamic>) {
        firstErrorState = state;
        break;
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
      return _MultiViewStateAggregate.error(firstErrorState);
    }

    if (hasInitialState) {
      return const _MultiViewStateAggregate.initial();
    }

    if (firstLoadingState != null) {
      final double loadingProgress = loadingProgressCount == 0
          ? 0.0
          : loadingProgressTotal / loadingProgressCount;

      return _MultiViewStateAggregate.loading(
        firstLoadingState,
        loadingProgress,
      );
    }

    if (firstEmptyState != null) {
      return _MultiViewStateAggregate.empty(firstEmptyState);
    }

    return const _MultiViewStateAggregate.data();
  }

  static VoidCallback? _createRetryCallback(
    List<ViewStateNotifier<dynamic>> providers,
  ) {
    final List<VoidCallback> retryCallbacks = <VoidCallback>[];

    for (final ViewStateNotifier<dynamic> provider in providers) {
      final ViewState<dynamic> state = provider.state;

      if (state is! ErrorState<dynamic>) {
        continue;
      }

      if (state.onRetry != null) {
        retryCallbacks.add(state.onRetry!);
      } else if (provider is AsyncViewStateNotifier) {
        retryCallbacks.add(provider.refresh);
      }
    }

    if (retryCallbacks.isEmpty) {
      return null;
    }

    return () {
      for (final VoidCallback retry in retryCallbacks) {
        retry();
      }
    };
  }

  static void handleListener<T>(
    T state,
    List<ViewStateNotifier<dynamic>> providers,
    ErrorStateListener? errorStateListener,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    DataStateListener<T>? dataStateListener,
  ) {
    final _MultiViewStateAggregate aggregate = _aggregate(providers);

    switch (aggregate.status) {
      case _MultiViewStateStatus.error:
        final ErrorState<dynamic> errorState = aggregate.errorState!;
        final VoidCallback? onRetry = _createRetryCallback(providers);

        errorStateListener?.call(
          errorState.errorInfo,
          errorState.error,
          errorState.stackTrace,
          onRetry,
        );

      case _MultiViewStateStatus.initial:
        initialStateListener?.call();

      case _MultiViewStateStatus.loading:
        final LoadingState<dynamic> loadingState = aggregate.loadingState!;

        loadingStateListener?.call(
          loadingState.message,
          aggregate.loadingProgress,
        );

      case _MultiViewStateStatus.empty:
        final EmptyState<dynamic> emptyState = aggregate.emptyState!;

        emptyStateListener?.call(emptyState.message);

      case _MultiViewStateStatus.data:
        dataStateListener?.call(state);
    }
  }

  static Widget handleBuilder<T>(
    T state,
    List<ViewStateNotifier<dynamic>> providers,
    ErrorStateBuilder? errorBuilder,
    BuildContext context,
    bool isSliver,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    DataStateBuilder<T> dataBuilder,
  ) {
    final _MultiViewStateAggregate aggregate = _aggregate(providers);

    switch (aggregate.status) {
      case _MultiViewStateStatus.error:
        return _buildErrorWidget(
          providers,
          errorBuilder,
          aggregate.errorState!,
          context,
          isSliver,
        );

      case _MultiViewStateStatus.initial:
        return ViewStateWidgetUtils.buildInitialWidget(
          context,
          initialBuilder,
          isSliver,
        );

      case _MultiViewStateStatus.loading:
        final LoadingState<dynamic> loadingState = aggregate.loadingState!;

        return ViewStateWidgetUtils.buildLoadingWidget(
          context,
          loadingBuilder,
          loadingState.message,
          aggregate.loadingProgress,
          isSliver,
        );

      case _MultiViewStateStatus.empty:
        final EmptyState<dynamic> emptyState = aggregate.emptyState!;

        return ViewStateWidgetUtils.buildEmptyWidget(
          context,
          emptyBuilder,
          emptyState.message,
          isSliver,
        );

      case _MultiViewStateStatus.data:
        return dataBuilder(state);
    }
  }

  static Widget _buildErrorWidget(
    List<ViewStateNotifier<dynamic>> providers,
    ErrorStateBuilder? errorBuilder,
    ErrorState<dynamic> errorState,
    BuildContext context,
    bool isSliver,
  ) {
    final VoidCallback? onRetry = _createRetryCallback(providers);
    return errorBuilder?.call(
          errorState.errorInfo,
          errorState.error,
          errorState.stackTrace,
          onRetry,
          isSliver,
        ) ??
        context.errorStateWidget(
          errorState.errorInfo,
          errorState.error,
          errorState.stackTrace,
          onRetry,
          isSliver,
        );
  }
}

enum _MultiViewStateStatus { error, initial, loading, empty, data }

class _MultiViewStateAggregate {
  const _MultiViewStateAggregate._({
    required this.status,
    this.errorState,
    this.loadingState,
    this.loadingProgress = 0.0,
    this.emptyState,
  });

  const _MultiViewStateAggregate.error(ErrorState<dynamic> state)
    : this._(status: _MultiViewStateStatus.error, errorState: state);

  const _MultiViewStateAggregate.initial()
    : this._(status: _MultiViewStateStatus.initial);

  const _MultiViewStateAggregate.loading(
    LoadingState<dynamic> state,
    double progress,
  ) : this._(
        status: _MultiViewStateStatus.loading,
        loadingState: state,
        loadingProgress: progress,
      );

  const _MultiViewStateAggregate.empty(EmptyState<dynamic> state)
    : this._(status: _MultiViewStateStatus.empty, emptyState: state);

  const _MultiViewStateAggregate.data()
    : this._(status: _MultiViewStateStatus.data);

  final _MultiViewStateStatus status;
  final ErrorState<dynamic>? errorState;
  final LoadingState<dynamic>? loadingState;
  final double loadingProgress;
  final EmptyState<dynamic>? emptyState;
}
