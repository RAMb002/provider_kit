import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/state_observer/change.dart';
import 'package:provider_kit/src/base/state_observer/state_observer.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';

abstract class StateNotifierBase<State> extends ChangeNotifier
    implements StateValueListenable<State> {
  // ProviderStateNotifier(super._State);

  /// Creates a [ChangeNotifier] that wraps this value.
  StateNotifierBase(this._state) {
    // ignore: invalid_use_of_protected_member
    _stateObserver.onCreate(this);
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  final StateObserver _stateObserver = StateNotifier.observer;

  /// The current state stored in this notifier.
  ///
  /// When the state is replaced with something that is not equal to the old
  /// state as evaluated by the equality operator ==, this class notifies its
  /// listeners.
  @override
  State get state => _state;
  State _state;
  set state(State newState) {
    try {
      if (_state == newState) {
        return;
      }
      onChange(Change<State>(currentState: this.state, nextState: newState));
      _state = newState;
      notifyListeners();
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
  }

  /// Called whenever a [change] occurs with the given [change].
  /// A [change] occurs when a new `state` is triggered.
  /// [onChange] is called before the `state` of the `StateNotifier` is updated.
  /// [onChange] is a great spot to add logging/analytics for a specific `StateNotifier`.
  ///
  /// **Note: `super.onChange` should always be called first.**
  /// ```dart
  /// @override
  /// void onChange(Change change) {
  ///   // Always call super.onChange with the current change
  ///   super.onChange(change);
  ///
  ///   // Custom onChange logic goes here
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [StateObserver] for observing [StateNotifier] behavior globally.
  ///
  @protected
  @mustCallSuper
  void onChange(Change<State> change) {
    // ignore: invalid_use_of_protected_member
    _stateObserver.onChange(this, change);
  }

  /// Called whenever an [error] occurs and notifies [StateObserver.onError].
  ///
  /// **Note: `super.onError` should always be called last.**
  ///
  /// ```dart
  /// @override
  /// void onError(Object error, StackTrace stackTrace) {
  ///   // Custom onError logic goes here
  ///
  ///   // Always call super.onError with the current error and stackTrace
  ///   super.onError(error, stackTrace);
  /// }
  /// ```
  @protected
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) {
    // ignore: invalid_use_of_protected_member
    _stateObserver.onError(this, error, stackTrace);
  }

  /// disposes the instance.
  /// This method should be called when the instance is no longer needed.
  /// Once [dispose] is called, the instance can no longer be used.
  @mustCallSuper
  @override
  void dispose() {
    // ignore: invalid_use_of_protected_member
    _stateObserver.onDispose(this);
    super.dispose();
  }

  @override
  String toString() => '${describeIdentity(this)}($state)';
}

abstract class StateValueListenable<State> implements Listenable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const StateValueListenable();

  /// The current value of the object. When the value changes, the callbacks
  /// registered with [addListener] will be invoked.
  State get state;
}
