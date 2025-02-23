import 'package:provider_kit/src/base/state_notifier_base.dart';
import 'package:provider_kit/src/base/state_observer/state_observer.dart';

class StateNotifier<State> extends StateNotifierBase<State> {
  StateNotifier(super.state);

  static StateObserver observer = const _DefaultStateObserver();
}

class _DefaultStateObserver extends StateObserver {
  const _DefaultStateObserver();
}
