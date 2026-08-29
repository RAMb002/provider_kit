import 'package:provider_kit/src/state/notifiers/state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// {@template provider_kit.view_state_notifier}
/// A notifier for managing a [ViewState] and exposing it to listeners.
///
/// [ViewStateNotifier] extends [StateNotifier] and provides a convenient
/// base class for notifiers whose state follows the [ViewState] model.
///
/// A view state can represent an initial, loading, data, empty, or error
/// condition.
///
/// ### Example Usage:
/// ```dart
/// class MyViewStateNotifier extends ViewStateNotifier<MyData> {
///   MyViewStateNotifier() : super(InitialState());
///
///   Future<void> fetchData() async {
///     try {
///       state = LoadingState();
///       final data = await fetchDataFromApi();
///       state = DataState(data);
///     } catch (error, stackTrace) {
///       state = ErrorState(error, stackTrace);
///     }
///   }
/// }
/// ```
///
/// {@endtemplate}

abstract class ViewStateNotifier<State>
    extends StateNotifier<ViewState<State>> {
  /// {@macro provider_kit.view_state_notifier}
  ViewStateNotifier(super.state);
}
