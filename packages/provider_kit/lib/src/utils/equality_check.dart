import 'package:collection/collection.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';

class ObjectKit {
  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  static bool isNotEqual<T extends Object?>(
      bool Function(T previous, T next)? rebuildWhen, T previous, T next) {
    return rebuildWhen?.call(previous, next) ?? previous != next;
  }

  static bool shouldNotify<T extends Object?>(
    T previous,
    T current,
    bool Function(T previous, T current)? when,
  ) {
    return when?.call(previous, current) ??
        !_equality.equals(previous, current);
  }

  static bool areProviderListsEqual<T>(
    List<StateValueListenable<T>> a,
    List<StateValueListenable<T>> b,
  ) {
    return ListEquality<StateValueListenable<T>>().equals(a, b);
  }
}
