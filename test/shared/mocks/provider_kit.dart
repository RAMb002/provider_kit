import 'dart:async';

import 'package:provider_kit/provider_kit.dart';

class MockProviderKit<T> extends ProviderKit<T> {
  final FutureOr<T> Function() fetchDataImpl;

  MockProviderKit({
    required this.fetchDataImpl,
    super.disableEmptystate,
  });

  @override
  FutureOr<T> fetchData() => fetchDataImpl();
}
