import 'package:provider_kit/provider_kit.dart';

/// A second independent notifier used by the multi-listenable examples.
class StepNotifier extends StateNotifier<int> {
  StepNotifier({int initialValue = 1}) : super(initialValue);

  void increment() => state++;

  void decrement() {
    if (state > 1) state--;
  }
}
