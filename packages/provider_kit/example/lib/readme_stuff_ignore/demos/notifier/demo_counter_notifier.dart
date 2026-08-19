import 'package:provider_kit/provider_kit.dart';

class DemoCounterNotifier extends StateNotifier<int> {
  DemoCounterNotifier() : super(0);

  void increment() {
    state++;
  }
}