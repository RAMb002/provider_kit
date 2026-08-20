import 'package:provider_kit/src/notifiers/notifiers.dart';
import 'package:provider_kit/src/states/states.dart';

class TestViewStateNotifier<T> extends ViewStateNotifier<T> {
  TestViewStateNotifier([ViewState<T>? initialState])
      : super(initialState ?? InitialState<T>());

  void emit(ViewState<T> newState) => state = newState;
}
