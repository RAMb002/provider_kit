import 'package:flutter/foundation.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/view_states.dart';

/// A base notifier class for managing state with [ValueNotifier].
/// Designed for use with provider-based state management.
///
///
abstract class ViewStateNotifier<State>
    extends StateNotifier<ViewState<State>> {
  ViewStateNotifier(super.state);
}
