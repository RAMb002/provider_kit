import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

class TestViewStateNotifier<T> extends ViewStateNotifier<T> {
  TestViewStateNotifier([ViewState<T>? initialState])
      : super(initialState ?? InitialState<T>());

  void emit(ViewState<T> newState) => state = newState;
}
