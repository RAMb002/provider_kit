import 'dart:async';

import 'package:provider_kit/provider_kit.dart';

class MockFutureNotifier<T> extends FutureNotifier<T> {
  final FutureOr<T> Function() fetchDataImpl;
  int refreshCalls = 0;
  MockFutureNotifier({required this.fetchDataImpl, super.disableEmptyState});

  @override
  Future<T> fetchData() async => fetchDataImpl();

  @override
  Future<void> refresh() async {
    refreshCalls++;
    super.refresh();
  }
}

class MockFutureNotifierWithoutRetry extends MockFutureNotifier<String> {
  MockFutureNotifierWithoutRetry({required super.fetchDataImpl});

  @override
  ErrorState<String> errorStateObject(Object error, StackTrace stackTrace) {
    return ErrorState<String>(error, stackTrace, onRetry: null);
  }
}
