import 'dart:async';

import 'package:provider_kit/provider_kit.dart';

class DemoMultiViewStateNotifier extends ViewStateNotifier<String> {
  DemoMultiViewStateNotifier({
    required this.data,
  }) : super(const LoadingState<String>());

  final String data;

  Timer? _timer;

  void load([int? milliseconds]) {
    int duration = milliseconds ?? 1500;
    _timer?.cancel();

    state = const LoadingState<String>();

    _timer = Timer(
      Duration(milliseconds: duration),
      () {
        if (!mounted) return;

        state = DataState<String>(data);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
