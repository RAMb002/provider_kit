import 'package:provider_kit/src/observer/notifier_observer.dart';
import 'package:provider_kit/src/state/state_notifier_base.dart';

/// {@template providerkit-statenotifier}
/// A notifier that holds a single state value and notifies listeners when it changes.
///
/// [StateNotifier] is the most basic state‑holding notifier in this package. It is
/// similar to `ValueNotifier` but integrates with the global [NotifierObserver]
/// for lifecycle tracking and debugging.
///
/// ### Usage
///
/// Extend [StateNotifier] with your own state type and update the state via the
/// `state` setter – listeners are notified automatically.
///
/// ```dart
/// class CounterNotifier extends StateNotifier<int> {
///   CounterNotifier() : super(0);
///
///   void increment() => state++;
///   void decrement() => state--;
/// }
/// ```
///
/// ### Global Observer
///
/// All notifiers (including [StateNotifier]) report their lifecycle events to the
/// global observer stored in [NotifierBase.observer]. To add logging or analytics,
/// assign a custom [NotifierObserver] implementation:
///
/// ```dart
/// class MyObserver extends NotifierObserver {
///   @override
///   void onChange(NotifierBase notifier, Change change) {
///     print('${notifier.runtimeType} changed: ${change.currentState} → ${change.nextState}');
///   }
/// }
///
/// void main() {
///   NotifierBase.observer = MyObserver();
///   runApp(MyApp());
/// }
/// ```
///
/// ### Parameters
/// - **`state`** – The initial state of the notifier.
/// {@endtemplate}
class StateNotifier<State> extends StateNotifierBase<State> {
  /// {@macro providerkit-statenotifier}
  StateNotifier(super.state);
}
