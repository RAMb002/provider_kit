import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

@internal
class RebuildScheduler {
  bool _scheduled = false;

  void request({
    required bool Function() isMounted,
    required VoidCallback rebuild,
  }) {
    if (!isMounted()) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_scheduled) {
        return;
      }

      _scheduled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;

        if (isMounted()) {
          rebuild();
        }
      });

      return;
    }

    rebuild();
  }
}
