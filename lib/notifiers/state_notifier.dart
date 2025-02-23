import 'package:provider_kit/src/base/state_notifier_base.dart';
import 'package:provider_kit/src/base/state_observer/state_observer.dart';

/// A class that extends [StateNotifierBase] to manage state changes and notify listeners.
///
/// The [StateNotifier] class is designed to handle state changes and notify listeners when the state changes.
/// It uses a [StateObserver] to observe state changes and perform actions such as logging or analytics.
///
/// ### Example Usage:
/// ```dart
/// class MyStateNotifier extends StateNotifier<MyState> {
///   MyStateNotifier() : super(MyState.initial());
///
///   void updateState(MyState newState) {
///     state = newState;
///   }
/// }
/// ```
///
/// ### State Observer:
/// The [StateNotifier] class uses a [StateObserver] to observe state changes.
/// By default, it uses a [_DefaultStateObserver] which does nothing.
/// Users can provide their own implementation of [StateObserver] to perform custom actions on state changes.
///
/// ```dart
/// class CustomStateObserver extends StateObserver {
///   @override
///   void onStateChange(State oldState, State newState) {
///     // Custom logic for handling state changes
///   }
/// }
///
/// void main() {
///   StateNotifier.observer = CustomStateObserver();
/// }
/// ```
///
/// ### Parameters:
/// - **`state`** (*Required*) **:** The initial state of the notifier.
class StateNotifier<State> extends StateNotifierBase<State> {
  StateNotifier(super.state);

  static StateObserver observer = const _DefaultStateObserver();
}

/// A default implementation of [StateObserver] that does nothing.
///
/// The [_DefaultStateObserver] class is used as the default observer for [StateNotifier].
/// It provides a no-op implementation of [StateObserver] methods.
class _DefaultStateObserver extends StateObserver {
  const _DefaultStateObserver();
}
