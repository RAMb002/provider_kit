import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

class TestCachedProvider extends AsyncViewStateNotifier<String>
    with DataStateCopyCacheMixin<String> {
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
    if (dataStateCopy != null) {
      state = dataStateCopy!;
    }
  }
}

// -----------------------------------------------------------------------------
// Test Suite
// -----------------------------------------------------------------------------
void main() {
  group('DataStateCopyCacheMixin with AsyncViewStateNotifier', () {
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
      // Explicit call to saveDataStateCopy is required to cache
      expect(provider.dataStateCopy, isNull);
      expect(provider.dataObjectCopy, isNull);
    });

    test('saveDataStateCopy updates cache when given a DataState', () async {
      await Future<void>.delayed(Duration.zero);

      final currentDataState = provider.state as DataState<String>;
      provider.saveDataStateCopy(currentDataState);

      expect(provider.dataStateCopy, equals(currentDataState));
      expect(provider.dataObjectCopy, equals('Initial Data'));
    });

    test('saveDataStateCopy overwrites existing cache with new DataState',
        () async {
      await Future<void>.delayed(Duration.zero);

      // 1. Cache initial data
      final firstState = provider.state as DataState<String>;
      provider.saveDataStateCopy(firstState);

      // 2. Cache updated data
      const secondState = DataState<String>('Updated Data');
      provider.saveDataStateCopy(secondState);

      // 3. Verify cache holds the latest saved DataState
      expect(provider.dataStateCopy, equals(secondState));
      expect(provider.dataObjectCopy, equals('Updated Data'));
    });

    test('saveDataStateCopy ignores non-DataState instances', () async {
      await Future<void>.delayed(Duration.zero);

      // 1. Save valid DataState
      final validState = provider.state as DataState<String>;
      provider.saveDataStateCopy(validState);

      // 2. Pass non-DataState values
      const loadingState = LoadingState<String>('Loading...');
      const errorState = ErrorState<String>('Error occurred');

      provider.saveDataStateCopy(loadingState);
      provider.saveDataStateCopy(errorState);
      provider.saveDataStateCopy(null);

      // 3. Cache retains the original DataState
      expect(provider.dataStateCopy, equals(validState));
      expect(provider.dataObjectCopy, equals('Initial Data'));
    });

    test(
        'supports filtering workflow by preserving master copy when state updates',
        () async {
      await Future<void>.delayed(Duration.zero);

      // 1. Save master copy
      final masterState = provider.state as DataState<String>;
      provider.saveDataStateCopy(masterState);

      // 2. Filter/mutate current state WITHOUT calling saveDataStateCopy
      provider.state = const DataState<String>('Filtered Data');

      // 3. Current state has filtered value, but cache still holds master copy
      expect(
          (provider.state as DataState<String>).data, equals('Filtered Data'));
      expect(provider.dataObjectCopy, equals('Initial Data'));

      // 4. Reset/restore filter from cache
      provider.restoreCachedData();
      expect(
          (provider.state as DataState<String>).data, equals('Initial Data'));
    });

    test(
        'cache preserves previous DataState across AsyncViewStateNotifier error refresh cycles',
        () async {
      await Future<void>.delayed(Duration.zero);

      // 1. Cache initial successful state
      final originalDataState = provider.state as DataState<String>;
      provider.saveDataStateCopy(originalDataState);

      // 2. Trigger error state transition
      provider.exceptionToThrow = Exception('Network error');
      await provider.refresh();

      expect(provider.state, isA<ErrorState<String>>());

      // 3. Attempting to save current error state leaves cache intact
      provider.saveDataStateCopy(provider.state);

      expect(provider.dataStateCopy, equals(originalDataState));
      expect(provider.dataObjectCopy, equals('Initial Data'));

      // 4. Restore state using cached copy
      provider.restoreCachedData();
      expect(provider.state, equals(originalDataState));
    });

    test('clearDataStateCopy purges all cached values', () async {
      await Future<void>.delayed(Duration.zero);

      provider.saveDataStateCopy(provider.state);
      expect(provider.dataStateCopy, isNotNull);
      expect(provider.dataObjectCopy, isNotNull);

      provider.clearDataStateCopy();

      expect(provider.dataStateCopy, isNull);
      expect(provider.dataObjectCopy, isNull);
    });

    test('dispose automatically clears cache in AsyncViewStateNotifier lifecycle',
        () async {
      await Future<void>.delayed(Duration.zero);

      provider.saveDataStateCopy(provider.state);
      expect(provider.dataStateCopy, isNotNull);

      provider.dispose();

      expect(provider.dataStateCopy, isNull);
      expect(provider.dataObjectCopy, isNull);
    });
  });
}
