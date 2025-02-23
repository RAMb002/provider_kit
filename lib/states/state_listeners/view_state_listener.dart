import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/state_listeners/state_listener.dart';
import 'package:provider_kit/states/view_states.dart';

class ViewStateListener<P extends ViewStateNotifier<T>, T>
    extends StateListener<P, ViewState<T>> {
  ViewStateListener({
    super.key,
    super.provider,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    super.listenWhen,
    super.shouldcallListenerOnInit,
    super.child,
  }) : super(
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
