class ObjectKit {

  static bool shouldNotify<T extends Object?>(
    T previous,
    T current,
    bool Function(T previous, T current)? when,
  ) {
    return when?.call(previous, current) ?? previous != current;
  }
}
