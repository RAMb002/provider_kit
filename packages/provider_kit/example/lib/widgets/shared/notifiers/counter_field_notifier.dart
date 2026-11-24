import 'package:flutter/foundation.dart';
import 'package:provider_kit/provider_kit.dart';

class CounterFieldNotifier extends ChangeNotifier {
  late final count = StateField(0);

  void increment() => count.state++;

  void decrement() => count.state--;

  void reset() => count.state = 0;

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }
}
