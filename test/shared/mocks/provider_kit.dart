import 'dart:async';

import 'package:provider_kit/provider_kit.dart';

class MockAsyncViewStateNotifier<T> extends AsyncViewStateNotifier<T> {
  final FutureOr<T> Function() fetchDataImpl;

  MockAsyncViewStateNotifier({
    required this.fetchDataImpl,
    super.disableEmptyState,
  });

  @override
  FutureOr<T> fetchData() => fetchDataImpl();
}
