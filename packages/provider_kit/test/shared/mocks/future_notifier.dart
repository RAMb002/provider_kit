import 'dart:async';
import 'package:provider_kit/src/view_state/notifiers/async/async_notifiers.dart';

class MockFutureNotifier<T> extends FutureNotifier<T> {
  final FutureOr<T> Function() buildImpl;
  int refreshCalls = 0;
  MockFutureNotifier({required this.buildImpl, super.disableEmptyState});

  @override
  Future<T> build() async => await buildImpl();

  @override
  Future<void> refresh() {
    refreshCalls++;
    return super.refresh();
  }
}
