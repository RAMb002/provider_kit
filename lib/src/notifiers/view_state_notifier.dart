import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/notifiers/state_notifier.dart';
import 'package:provider_kit/src/states/view_states.dart';

/// {@template providerkit-viewstatenotifier}
/// A base notifier class for managing state with [ValueNotifier].
/// Designed for use with provider-based state management.
///
/// The [ViewStateNotifier] class extends [StateNotifier] and is used to manage view states.
/// It is designed to work with provider-based state management and provides a way to handle different view states
/// such as loading, error, and data states.
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
///     } catch (e) {
///       state = ErrorState(e.toString());
///     }
///   }
/// }
/// ```
///
/// ### Parameters:
/// - **`state`** (*Required*) **:** The initial state of the notifier.
/// {@endtemplate}

abstract class ViewStateNotifier<State>
    extends StateNotifier<ViewState<State>> {
  /// {@macro providerkit-viewstatenotifier}
  ViewStateNotifier(super.state);
}
