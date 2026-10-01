library provider_kit_multi_state;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/utils/equality_check.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/src/view_state/multi_view_state/empty_state_behaviour.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/utils/multi_view_state_widget_utils.dart';

part 'internal/dependency_tracker.dart';
part 'internal/multi_state_base.dart';
part 'extension/watch_extension.dart';
part 'widgets/multi_state_listener.dart';
part 'widgets/multi_state_builder.dart';
part 'widgets/multi_state_consumer.dart';
part '../../view_state/multi_view_state/multi_view_state_dependency_delegate.dart';
part '../../view_state/multi_view_state/widgets/multi_view_state_listener.dart';
part '../../view_state/multi_view_state/widgets/multi_view_state_builder.dart';
part '../../view_state/multi_view_state/widgets/multi_view_state_consumer.dart';




