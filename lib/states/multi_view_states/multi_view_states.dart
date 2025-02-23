import 'package:flutter/widgets.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/states.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/view_state_widgets_provider.dart';

enum _AggregatedViewState {
  error,
  initial,
  loading,
  empty,
  data,
  unknown,
}

class MultiViewStateConsumer<T> extends MultiStateConsumer<ViewState<T>> {
  MultiViewStateConsumer(
      {super.key,
      required super.providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? failureBuilder,
      required DataStateBuilder<List<DataState<T>>> dataBuilder,
      super.rebuildWhen,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<List<DataState<T>>>? dataStateListener,
      ListenWhen<List<ViewState<T>>>? listenWhen,
      super.shouldcallListenerOnInit,
      bool isSliver = false})
      : super(
          builder: (context, states, child) =>
              MultiViewStateBuilder._multiViewStateBuilder(
                  states,
                  providers,
                  failureBuilder,
                  context,
                  isSliver,
                  initialBuilder,
                  loadingBuilder,
                  emptyBuilder,
                  dataBuilder),
          listenWhen: (previous, next) =>
              MultiViewStateListener._listenWhen(listenWhen, previous, next),
          listener: (context, states) =>
              MultiViewStateListener._multiStateListener(
                  states,
                  providers,
                  errorStateListener,
                  initialStateListener,
                  loadingStateListener,
                  emptyStateListener,
                  dataStateListener),
        );
}

class MultiViewStateListener<T> extends MultiStateListener<ViewState<T>> {
  MultiViewStateListener({
    super.key,
    required super.providers,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<List<DataState<T>>>? dataStateListener,
    ListenWhen<List<ViewState<T>>>? listenWhen,
    super.shouldcallListenerOnInit,
    super.child,
  }) : super(
          listenWhen: (previous, next) =>
              _listenWhen(listenWhen, previous, next),
          listener: (context, states) {
            _multiStateListener(
              states,
              providers,
              errorStateListener,
              initialStateListener,
              loadingStateListener,
              emptyStateListener,
              dataStateListener,
            );
          },
        );

  static bool _listenWhen<T>(ListenWhen<List<ViewState<T>>>? listenWhen,
      List<ViewState<T>> previous, List<ViewState<T>> next) {
    if (listenWhen != null) return listenWhen.call(previous, next);
    final previousState = _combinedState(previous);
    final nextState = _combinedState(next);
    return previousState != nextState;
  }

  static void _multiStateListener<T>(
      List<ViewState<T>> states,
      List<StateNotifier<ViewState<T>>> providers,
      ErrorStateListener? errorStateListener,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      DataStateListener<List<DataState<T>>>? dataStateListener) {
    final errorStates = ViewStateBase.getErrorStates(states);

    if (errorStates.isNotEmpty) {
      final errorState = errorStates.first;
      onRetry() => ViewStateBase.onRetry(providers);
      errorStateListener?.call(errorState.message, onRetry,
          errorState.exception, errorState.stackTrace);
      return;
    }
    if (ViewStateBase.hasInitialState(states)) {
      initialStateListener?.call();
      return;
    }
    final loadingStates = ViewStateBase.getLoadingStates(states);
    if (loadingStates.isNotEmpty) {
      loadingStateListener?.call(loadingStates.first.message,
          ViewStateBase.getCombinedLoadingProgress(loadingStates));
      return;
    }
    final emptyStates = ViewStateBase.getEmptyStates(states);
    if (emptyStates.isNotEmpty) {
      emptyStateListener?.call(emptyStates.first.message);
      return;
    }
    dataStateListener?.call(states.cast<DataState<T>>().toList());
    return;
  }

  static _AggregatedViewState _combinedState<T>(List<ViewState<T>> states) {
    if (ViewStateBase.hasErrorState(states)) return _AggregatedViewState.error;
    if (ViewStateBase.hasInitialState(states)) {
      return _AggregatedViewState.initial;
    }
    if (ViewStateBase.hasLoadingState(states)) {
      return _AggregatedViewState.loading;
    }
    if (ViewStateBase.hasEmptyState(states)) return _AggregatedViewState.empty;
    if (ViewStateBase.allAreDataState(states)) return _AggregatedViewState.data;
    return _AggregatedViewState.unknown;
  }
}

class MultiViewStateBuilder<T> extends MultiStateBuilder<ViewState<T>> {
  MultiViewStateBuilder(
      {super.key,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? failureBuilder,
      required DataStateBuilder<List<DataState<T>>> dataBuilder,
      super.rebuildWhen,
      bool isSliver = false,
      required super.providers})
      : super(
          builder: (context, states, child) {
            return _multiViewStateBuilder(
                states,
                providers,
                failureBuilder,
                context,
                isSliver,
                initialBuilder,
                loadingBuilder,
                emptyBuilder,
                dataBuilder);
          },
        );

  static Widget _multiViewStateBuilder<T>(
      List<ViewState<T>> states,
      List<StateNotifier<ViewState<T>>> providers,
      ErrorStateBuilder? failureBuilder,
      BuildContext context,
      bool isSliver,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      DataStateBuilder<List<DataState<T>>> dataBuilder) {
    if (ViewStateBase.hasErrorState(states)) {
      return _buildErrorWidget(
          providers, failureBuilder, states, context, isSliver);
    }
    if (ViewStateBase.hasInitialState(states)) {
      return ViewStateBase.buildInitialWidget(
          context, initialBuilder, isSliver);
    }
    final loadingStates = ViewStateBase.getLoadingStates(states);
    if (loadingStates.isNotEmpty) {
      return ViewStateBase.buildLoadingWidget(
          context,
          loadingBuilder,
          loadingStates.first.message,
          ViewStateBase.getCombinedLoadingProgress(loadingStates),
          isSliver);
    }
    final emptyStates = ViewStateBase.getEmptyStates(states);
    if (emptyStates.isNotEmpty) {
      return ViewStateBase.buildEmptyWidget(
          context, emptyBuilder, emptyStates.first.message, isSliver);
    }
    return dataBuilder(states.cast<DataState<T>>().toList());
  }

  static Widget _buildErrorWidget<T>(
    List<StateNotifier<ViewState<T>>> providers,
    ErrorStateBuilder? errorBuilder,
    List<ViewState<T>> states,
    BuildContext context,
    bool isSliver,
  ) {
    final errorStates = states.whereType<ErrorState<T>>().toList();

    void onRetry() {
      ViewStateBase.onRetry(providers);
    }

    final errorMessage = errorStates.first.message;
    final exception = errorStates.first.exception;
    final stackTrace = errorStates.first.stackTrace;
    return errorBuilder?.call(
          errorMessage,
          onRetry,
          exception,
          stackTrace,
          isSliver,
        ) ??
        context.errorStateWidget(
            errorMessage, onRetry, exception, stackTrace, isSliver);
  }
}
