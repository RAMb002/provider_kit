// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

import '../notifiers/state_notifier.dart';

class ObjectKit {
  static bool isNotEqual<T extends Object?>(
      bool Function(T previous, T next)? rebuildWhen, T previous, T next) {
    return rebuildWhen?.call(previous, next) ?? previous != next;
  }

  static bool areProviderListsEqual<T>(
    List<StateNotifier<T>> a,
    List<StateNotifier<T>> b,
  ) {
    return ListEquality<StateNotifier<T>>().equals(a, b);
  }
}
