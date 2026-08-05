import 'package:collection/collection.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';

class ObjectKit {
  static bool isNotEqual<T extends Object?>(
      bool Function(T previous, T next)? rebuildWhen, T previous, T next) {
    return rebuildWhen?.call(previous, next) ?? previous != next;
  }

  static bool areProviderListsEqual<T>(
    List<StateValueListenable<T>> a,
    List<StateValueListenable<T>> b,
  ) {
    return ListEquality<StateValueListenable<T>>().equals(a, b);
  }
}
