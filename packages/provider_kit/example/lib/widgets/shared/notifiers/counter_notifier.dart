import 'package:provider_kit/provider_kit.dart';

/// A small counter notifier shared by the State Widgets examples.
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier({int initialValue = 0}) : super(initialValue);

  void increment() => state++;

  void decrement() => state--;

  void add(int value) => state += value;

  void reset() => state = 0;
}
