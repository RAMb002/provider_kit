import 'package:provider_kit/provider_kit.dart';

class ExampleProvider extends StateNotifier<int> {
  ExampleProvider(super.state);

  void increment() {
    state += 1;
  }
}

class ProfileProvider extends StateNotifier<String> {
  ProfileProvider() : super('Alex');

  int _index = 0;

  void updateName() {
    const names = [
      'Alex',
      'John',
      'Emma',
      'Sophia',
      'Daniel',
      'Olivia',
    ];

    _index = (_index + 1) % names.length;
    state = names[_index];
  }
}

class CartProvider extends StateNotifier<int> {
  CartProvider() : super(0);

  void addItem() {
    state++;
  }

  void removeItem() {
    if (state > 0) {
      state--;
    }
  }
}

class NotificationProvider extends StateNotifier<int> {
  NotificationProvider() : super(0);

  void addNotification() {
    state++;
  }

  void clearNotifications() {
    state = 0;
  }
}
