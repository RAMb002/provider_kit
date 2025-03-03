
class ObjectKit {
  static bool isNotEqual<T extends Object?>(
      bool Function(T previous, T next)? rebuildWhen, T previous, T next) {
    return rebuildWhen?.call(previous, next) ?? previous != next;
  }
}
