import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/notifier_base.dart';
import 'package:provider_kit/src/base/observer/change.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';

abstract class StateNotifierBase<State> extends NotifierBase<State>
    implements StateValueListenable<State> {
  StateNotifierBase(this._state);

  /// The current state stored in this notifier.
  ///
  /// When the state is replaced with a value that is not equal to the current
  /// state, listeners are notified.
  @override
  State get state => _state;

  State _state;

  set state(State newState) {
    assert(NotifierBase.debugAssertNotDisposed(
      this,
      'set state ($State)',
    ));

    // Runtime protection (important for async notifiers in release).
    if (!mounted) {
      return;
    }

    try {
      if (_state == newState) return;

      onChange(
        Change<State>(
          currentState: _state,
          nextState: newState,
        ),
      );

      _state = newState;
      notifyListeners();
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
  }

  @override
  String toString() => '${describeIdentity(this)}($state)';
}
