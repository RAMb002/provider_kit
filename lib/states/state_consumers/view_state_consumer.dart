import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/state_builders/view_state_builder.dart';
import 'package:provider_kit/states/state_consumers/state_consumer.dart';
import 'package:provider_kit/states/view_states.dart';

class ViewStateConsumer<P extends ViewStateNotifier<T>, T>
    extends StateConsumer<P, ViewState<T>> {
  ViewStateConsumer({
    super.key,
    super.provider,
    super.rebuildWhen,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    required DataStateBuilder<T> dataBuilder,
    ErrorStateBuilder? errorBuilder,
    super.listenWhen,
    InitialStateListener? initialStateListener,
    DataStateListener<T>? dataStateListener,
    EmptyStateListener? emptyStateListener,
    LoadingStateListener? loadingStateListener,
    ErrorStateListener? errorStateListener,
    super.shouldcallListenerOnInit,
    bool isSliver = false,
  }) : super(
          builder: (context, state, child) {
            return ViewStateBuilder.buildStateWidget<P, T>(
              context,
              provider,
              state,
              initialBuilder,
              dataBuilder,
              errorBuilder,
              loadingBuilder,
              emptyBuilder,
              isSliver,
            );
          },
          listener: (context, state) {
            state.when(
              initialState: () => initialStateListener?.call(),
              loadingState: (message, progress) =>
                  loadingStateListener?.call(message, progress),
              dataState: (data) => dataStateListener?.call(data),
              emptyState: (message) => emptyStateListener?.call(message),
              errorState: (errorMessage, onRetry, exception, stackTrace) =>
                  errorStateListener?.call(
                      errorMessage, onRetry, exception, stackTrace),
            );
          },
        );
}
