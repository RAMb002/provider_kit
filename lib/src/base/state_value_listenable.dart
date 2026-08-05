import 'package:flutter/foundation.dart';

/// A listenable object that exposes a state value.
///
/// This interface is the foundation of ProviderKit's generic state widgets,
/// such as `StateBuilder`, `StateListener`, `StateConsumer`, and their
/// multi-state counterparts.
///
/// All ProviderKit notifiers implement this interface by default.
///
/// You can implement this interface in your own classes to integrate
/// seamlessly with ProviderKit's state widgets.
abstract class StateValueListenable<T> implements Listenable {

  /// The current state.
  ///
  /// Registered listeners are notified whenever the state changes.
  T get state;
}