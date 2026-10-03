import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

class TestCachedProvider extends AsyncViewStateNotifier<String>
    with DataStateCacheMixin<String> {
  String? dataToReturn;
  Exception? exceptionToThrow;

  TestCachedProvider({
    this.dataToReturn = 'Initial Data',
    this.exceptionToThrow,
    super.initialState,
    super.disableEmptyState,
  });

  @override
  FutureOr<String> fetchData() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    return dataToReturn ?? '';
  }

  void restoreCachedData() {
    final cachedState = cachedDataState;

    if (cachedState != null) {
      state = cachedState;
    }
  }
}

// -----------------------------------------------------------------------------
// Test Suite
// -----------------------------------------------------------------------------
void main() {
  group('DataStateCacheMixin with AsyncViewStateNotifier', () {
    late TestCachedProvider provider;

    setUp(() {
      provider = TestCachedProvider();
    });

    tearDown(() {
      try {
        provider.dispose();
      } catch (_) {}
    });

    test('initial cache values are null', () async {
      await Future<void>.delayed(Duration.zero);

      expect(provider.state, isA<DataState<String>>());

      // Caching is explicit.
      expect(provider.cachedDataState, isNull);
      expect(provider.cachedData, isNull);
    });

    test('cacheDataState caches the provided DataState', () async {
      await Future<void>.delayed(Duration.zero);

      final currentDataState = provider.state as DataState<String>;

      provider.cacheDataState(currentDataState);

      expect(provider.cachedDataState, equals(currentDataState));
      expect(provider.cachedData, equals('Initial Data'));
    });

    test('cacheDataState overwrites the existing cache', () async {
      await Future<void>.delayed(Duration.zero);

      // Cache initial data.
      final firstState = provider.state as DataState<String>;
      provider.cacheDataState(firstState);

      // Cache updated data.
      const secondState = DataState<String>('Updated Data');
      provider.cacheDataState(secondState);

      expect(provider.cachedDataState, equals(secondState));
      expect(provider.cachedData, equals('Updated Data'));
    });

    test(
      'preserves cached data when the current state is replaced with filtered data',
      () async {
        await Future<void>.delayed(Duration.zero);

        // Save the original data.
        final originalState = provider.state as DataState<String>;
        provider.cacheDataState(originalState);

        // Replace the current state with filtered/modified data.
        provider.state = const DataState<String>('Filtered Data');

        // Current state changed, but the cache remains unchanged.
        expect(
          (provider.state as DataState<String>).data,
          equals('Filtered Data'),
        );
        expect(provider.cachedDataState, equals(originalState));
        expect(provider.cachedData, equals('Initial Data'));

        // Restore the original state.
        provider.restoreCachedData();

        expect(provider.state, equals(originalState));
        expect(
          (provider.state as DataState<String>).data,
          equals('Initial Data'),
        );
      },
    );

    test(
      'preserves cached DataState across AsyncViewStateNotifier error refresh cycles',
      () async {
        await Future<void>.delayed(Duration.zero);

        // Cache the original successful state.
        final originalDataState = provider.state as DataState<String>;
        provider.cacheDataState(originalDataState);

        // Trigger an error.
        provider.exceptionToThrow = Exception('Network error');
        await provider.refresh();

        expect(provider.state, isA<ErrorState<String>>());

        // The cached DataState remains unchanged.
        expect(provider.cachedDataState, equals(originalDataState));
        expect(provider.cachedData, equals('Initial Data'));

        // Restore the cached state.
        provider.restoreCachedData();

        expect(provider.state, equals(originalDataState));
      },
    );

    test('clearDataStateCache clears all cached values', () async {
      await Future<void>.delayed(Duration.zero);

      final dataState = provider.state as DataState<String>;
      provider.cacheDataState(dataState);

      expect(provider.cachedDataState, isNotNull);
      expect(provider.cachedData, isNotNull);

      provider.clearDataStateCache();

      expect(provider.cachedDataState, isNull);
      expect(provider.cachedData, isNull);
    });

    test('dispose automatically clears the cache', () async {
      await Future<void>.delayed(Duration.zero);

      final dataState = provider.state as DataState<String>;
      provider.cacheDataState(dataState);

      expect(provider.cachedDataState, isNotNull);
      expect(provider.cachedData, isNotNull);

      provider.dispose();

      expect(provider.cachedDataState, isNull);
      expect(provider.cachedData, isNull);
    });
  });
}
