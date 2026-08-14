import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

class TestExCachedProvider extends AsyncViewStateNotifier<List<String>>
    with ExViewStateCacheMixin<List<String>> {
  List<String>? dataToReturn;
  Exception? exceptionToThrow;

  TestExCachedProvider({
    this.dataToReturn = const ['Item A', 'Item B'],
    this.exceptionToThrow,
    super.initialState,
    super.disableEmptyState,
  });

  @override
  FutureOr<List<String>> fetchData() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return dataToReturn ?? [];
  }
}

// -----------------------------------------------------------------------------
// Test Suite
// -----------------------------------------------------------------------------
void main() {
  group(
      'ExViewStateCacheMixin with AsyncViewStateNotifier Tests (Previous State Cache)',
      () {
    late TestExCachedProvider provider;

    tearDown(() {
      try {
        provider.dispose();
      } catch (_) {}
    });

    test('caches LoadingState when transitioning away to DataState', () async {
      provider = TestExCachedProvider(dataToReturn: ['Apple']);

      await pumpEventQueue();

      expect(provider.exLoadingState, isA<LoadingState<List<String>>>());
    });

    test(
        'caches DataState and exDataStateObject when transitioning away to another state',
        () async {
      provider = TestExCachedProvider(dataToReturn: ['Apple', 'Banana']);

      await pumpEventQueue();

      provider.exceptionToThrow = Exception('Network error');
      final refreshFuture = provider.refresh();
      await pumpEventQueue();
      await refreshFuture;

      expect(provider.exDataState, isA<DataState<List<String>>>());
      expect(provider.exDataStateObject, equals(['Apple', 'Banana']));
    });

    test('caches EmptyState when transitioning away after empty fetch',
        () async {
      provider = TestExCachedProvider(dataToReturn: []);

      await pumpEventQueue();

      provider.dataToReturn = ['New Data'];
      final refreshFuture = provider.refresh();
      await pumpEventQueue();
      await refreshFuture;

      expect(provider.exEmptyState, isA<EmptyState<List<String>>>());
    });

    test('caches ErrorState when transitioning away after error', () async {
      provider =
          TestExCachedProvider(exceptionToThrow: Exception('Initial error'));

      await pumpEventQueue();

      provider.exceptionToThrow = null;
      provider.dataToReturn = ['Recovered Data'];
      final refreshFuture = provider.refresh();
      await pumpEventQueue();
      await refreshFuture;

      expect(provider.exErrorState, isA<ErrorState<List<String>>>());
    });

    test('clearCache purges all previous state references', () async {
      provider = TestExCachedProvider(dataToReturn: ['Data']);
      await pumpEventQueue();

      provider.exceptionToThrow = Exception('Error');
      final refreshFuture = provider.refresh();
      await pumpEventQueue();
      await refreshFuture;

      expect(provider.exDataState, isNotNull);

      provider.clearCache();

      expect(provider.exInitialState, isNull);
      expect(provider.exLoadingState, isNull);
      expect(provider.exEmptyState, isNull);
      expect(provider.exErrorState, isNull);
      expect(provider.exDataState, isNull);
      expect(provider.exDataStateObject, isNull);
    });

    test(
        'dispose automatically purges cache in AsyncViewStateNotifier lifecycle',
        () async {
      provider = TestExCachedProvider(dataToReturn: ['Data']);
      await pumpEventQueue();

      provider.exceptionToThrow = Exception('Error');
      final refreshFuture = provider.refresh();
      await pumpEventQueue();
      await refreshFuture;

      expect(provider.exDataState, isNotNull);

      provider.dispose();

      expect(provider.exInitialState, isNull);
      expect(provider.exLoadingState, isNull);
      expect(provider.exEmptyState, isNull);
      expect(provider.exErrorState, isNull);
      expect(provider.exDataState, isNull);
      expect(provider.exDataStateObject, isNull);
    });
  });
}
