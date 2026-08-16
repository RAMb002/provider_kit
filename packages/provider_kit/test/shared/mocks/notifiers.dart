import 'package:provider_kit/provider_kit.dart';

/// Mock StateNotifier with string state for basic testing
/// **Reusable for:** StateListener, StateBuilder, StateConsumer tests
class TestStateNotifier<T> extends StateNotifier<T> {
  TestStateNotifier({required T initialState}) : super(initialState);

  void updateState(T newState) {
    state = newState;
  }

  void reset(T initialState) {
    state = initialState;
  }
}

/// Mock StateNotifier with integer state for numeric testing
/// **Reusable for:** StateListener, StateBuilder, StateConsumer tests
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier({int initialState = 0}) : super(initialState);

  void increment() {
    state = state + 1;
  }

  void decrement() {
    state = state - 1;
  }

  void reset() {
    state = 0;
  }

  void updateState(int newState) {
    state = newState;
  }
}

/// Mock StateNotifier with list state for collection testing
/// **Reusable for:** StateListener, StateBuilder with complex types
class ListNotifier extends StateNotifier<List<String>> {
  ListNotifier({List<String> initialState = const []}) : super(initialState);

  void addItem(String item) {
    state = [...state, item];
  }

  void add(String item) {
    state = [...state, item];
  }

  void removeItem(String item) {
    state = state.where((element) => element != item).toList();
  }

  void clear() {
    state = [];
  }
}

/// Mock StateNotifier with boolean state for toggle testing
/// **Reusable for:** StateListener, StateBuilder with binary states
class ToggleNotifier extends StateNotifier<bool> {
  ToggleNotifier({bool initialState = false}) : super(initialState);

  void toggle() {
    state = !state;
  }

  void setTrue() {
    state = true;
  }

  void setFalse() {
    state = false;
  }
}

/// The base counter provider that increments by 1.
class CounterProvider extends StateNotifier<int> {
  CounterProvider([super.initialState = 0]);

  void increment() {
    state = state + 1;
  }
}

/// A specialized counter provider that starts at 10 and increments by 10.
class DecadeCounterProvider extends CounterProvider {
  DecadeCounterProvider() : super(10);

  @override
  void increment() {
    state = state + 10;
  }
}

/// The utility class used throughout the test suites to supply
/// tracking configurations and batch mutations.
class MyProvider {
  MyProvider() {
    providersOne = [
      CounterProvider(), // Initial state: 0
      DecadeCounterProvider(), // Initial state: 10
    ];

    providersTwo = [
      CounterProvider(), // Initial state: 0
      DecadeCounterProvider(), // Initial state: 10
    ];
  }

  late final List<CounterProvider> providersOne;
  late final List<CounterProvider> providersTwo;

  /// Iterates through the given list and increments each provider.
  void incrementProviders(List<CounterProvider> targetProviders) {
    for (final provider in targetProviders) {
      provider.increment();
    }
  }
}
