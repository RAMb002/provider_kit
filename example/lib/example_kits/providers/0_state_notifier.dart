import 'package:provider_kit/provider_kit.dart';

class ExampleProvider extends StateNotifier<int> {
  ExampleProvider(super.state);

  void increment() {
    state += 1;
  }
}