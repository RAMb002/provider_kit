import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/states/state_builders/state_builder.dart';
import 'package:provider_kit/src/states/state_consumers/state_consumer.dart';
import 'package:provider_kit/src/states/state_listeners/state_listener.dart';

/// A type alias for [StateBuilder] when working directly with a
/// [StateValueListenable] instance, such as a [StateNotifier].
///
/// Use this typedef when you already have a concrete
/// [StateValueListenable] instance (such as a [StateNotifier]) and want to
/// pass it directly to the `provider` parameter, without typing the verbose
/// generic `<StateValueListenable<T>, T>` every time.
///
/// ## Example
///
/// ```dart
/// final counterNotifier = CounterNotifier(); // extends StateNotifier<int>
///
/// NotifierBuilder<int>(
///   provider: counterNotifier, // Pass the instance directly
///   builder: (context, state, child) {
///     return Text('Count: $state');
///   },
/// )
/// ```
/// If your notifier is provided via the widget tree (e.g., using `Provider`),
/// prefer the full [StateBuilder] with your custom provider type instead:
///
/// ```dart
/// StateBuilder<CounterProvider, int>(
///   builder: (context, state, child) => Text('$state'),
/// )
/// ```
typedef NotifierBuilder<T> = StateBuilder<StateValueListenable<T>, T>;

/// A convenient alias for [StateListener] when working directly with a
/// [StateValueListenable] instance, such as a [StateNotifier].
///
/// Use this typedef when you already have a concrete
/// [StateValueListenable] instance (such as a [StateNotifier]) and want to
/// pass it directly to the `provider` parameter, without typing the verbose
/// generic `<StateValueListenable<T>, T>` every time.
///
/// ## Example
///
/// ```dart
/// final counterNotifier = CounterNotifier(); // extends StateNotifier<int>
///
/// NotifierListener<int>(
///   provider: counterNotifier, // Pass the instance directly
///   listenWhen: (previous, current) => previous != current,
///   listener: (context, state) {
///     // Execute side effects when the state changes
///   },
///   child: YourWidget(),
/// )
/// ```
///
/// If your notifier is provided via the widget tree (e.g., using `Provider`),
/// prefer the full [StateListener] with your custom provider type instead:
///
/// ```dart
/// StateListener<CounterProvider, int>(
///   listener: (context, state) { ... },
///   child: YourWidget(),
/// )
/// ```
typedef NotifierListener<T> = StateListener<StateValueListenable<T>, T>;

/// A convenient alias for [StateConsumer] when working directly with a
/// [StateValueListenable] instance, such as a [StateNotifier].
///
/// Use this typedef when you already have a concrete
/// [StateValueListenable] instance (such as a [StateNotifier]) and want to
/// pass it directly to the `provider` parameter, without typing the verbose
/// generic `<StateValueListenable<T>, T>` every time.
///
/// [StateConsumer] combines listening to state changes with building widgets,
/// and provides the notifier instance inside the builder for method calls.
///
/// ## Example
///
/// ```dart
/// final counterNotifier = CounterNotifier(); // extends StateNotifier<int>
///
/// NotifierConsumer<int>(
///   provider: counterNotifier, // Pass the instance directly
///   builder: (context, state, child) {
///     return Text('Count: $state');
///   },
/// )
/// ```
///
/// If your notifier is provided via the widget tree (e.g., using `Provider`),
/// prefer the full [StateConsumer] with your custom provider type instead:
///
/// ```dart
/// StateConsumer<CounterProvider, int>(
///   builder: (context, state, child) { ... },
/// )
/// ```
typedef NotifierConsumer<T> = StateConsumer<StateValueListenable<T>, T>;