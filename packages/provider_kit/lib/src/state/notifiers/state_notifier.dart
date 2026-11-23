import 'package:provider_kit/src/observer/notifier_observer.dart';
import 'package:provider_kit/src/state/state_notifier_base.dart';

/// {@template provider_kit.state_notifier}
/// An abstract base class for notifiers that hold a single state value
/// and notify listeners when it changes.
///
/// [StateNotifier] is the foundation for custom state-holding notifiers in
/// ProviderKit. It is similar to `ValueNotifier` but integrates with the
/// global [NotifierObserver] for lifecycle tracking and debugging.
///
/// It cannot be instantiated directly. Extend [StateNotifier] to implement
/// your own state management logic and update the state through its
/// protected `state` setter.
///
/// ### Usage
///
/// Create a custom notifier by extending [StateNotifier]:
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
/// ### Listening to State
///
/// Use `StateBuilder` to rebuild a widget whenever the notifier's state
/// changes. You can pass the notifier directly:
///
/// ```dart
/// final counter = CounterNotifier();
///
/// StateBuilder<int>(
///   listenable: counter,
///   builder: (context, state, child) {
///     return Text('Count: $state');
///   },
/// );
/// ```
///
/// When the notifier is provided through the widget tree using the
/// `provider` package, use `StateBuilder.of` to retrieve and listen to it:
///
/// ```dart
/// StateBuilder.of<CounterNotifier, int>(
///   builder: (context, state, child) {
///     return Text('Count: $state');
///   },
/// );
/// ```
///
/// ProviderKit offers other state widgets for different use cases:
///
/// - `StateListener` listens for state changes and executes callbacks
///   without rebuilding its child.
/// - `StateConsumer` combines state building and listening in one widget.
/// - `StateBuilder.multi`, `StateListener.multi`, and
///   `StateConsumer.multi` support working with multiple listenables.
///
/// Choose the widget that best fits your use case.
///
/// ### Global Observer
///
/// All notifiers (including [StateNotifier]) report their lifecycle events to
/// the global [NotifierObserver]. Configure a custom observer using
/// `ProviderKit.configure` to add logging, analytics, or debugging:
///
/// ```dart
/// class MyObserver extends NotifierObserver {
///   @override
///   void onChange(NotifierBase notifier, Change change) {
///     print(
///       '${notifier.runtimeType} changed: '
///       '${change.currentState} → ${change.nextState}',
///     );
///   }
/// }
///
/// void main() {
///   ProviderKit.configure(observer: MyObserver());
///   runApp(MyApp());
/// }
/// ```
/// {@endtemplate}
abstract class StateNotifier<State> extends StateNotifierBase<State> {
  /// {@macro provider_kit.state_notifier}
  StateNotifier(super.state);
}
