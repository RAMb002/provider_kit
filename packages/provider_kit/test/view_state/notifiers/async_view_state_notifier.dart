import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

mixin _AsyncNotifierHooksMixin on AsyncViewStateNotifier<int> {
  Future<void> exerciseHooks({
    required Object error,
    required StackTrace stackTrace,
  }) async {
    invalidateBuild();
    setInitial();
    setLoading(message: 'Loading', progress: 0.5);
    setData(42);
    setEmpty('Empty');
    setError(error, stackTrace);

    await refresh();
    await rebuild();

    final isStale = checkStaleness();
    isStale();
  }
}

class _TestAsyncNotifier extends AsyncViewStateNotifier<int>
    with _AsyncNotifierHooksMixin {
  _TestAsyncNotifier(this.events);

  final List<String> events;

  @override
  void onInitialize() {
    events.add('initialize');
    super.onInitialize();
  }

  @override
  Future<void> refresh() async {
    events.add('refresh');
  }

  @override
  Future<void> rebuild() async {
    events.add('rebuild');
  }

  @override
  bool Function() checkStaleness() {
    events.add('checkStaleness');

    return () {
      events.add('isStale');
      return false;
    };
  }

  @override
  void invalidateBuild() {
    events.add('invalidateBuild');
  }

  @override
  void setInitial() {
    events.add('setInitial');
  }

  @override
  void setLoading({String? message, double? progress}) {
    events.add('setLoading:$message:$progress');
  }

  @override
  void setData(int data) {
    events.add('setData:$data');
  }

  @override
  void setEmpty([String? message]) {
    events.add('setEmpty:$message');
  }

  @override
  void setError(Object error, StackTrace stackTrace) {
    events.add('setError:$error');
  }
}

void main() {
  group('AsyncViewStateNotifier', () {
    test('calls onInitialize after construction', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      addTearDown(notifier.dispose);
      events.add('constructed');
      await Future<void>.delayed(Duration.zero);
      expect(events, ['constructed', 'initialize']);
    });

    test('calls onInitialize only once', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(
        events.where((event) => event == 'initialize').length,
        1,
      );
    });

    test('does not call onInitialize after disposal', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      notifier.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });

    test('exposes shared operations to reusable mixins', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      events.clear();

      final error = StateError('Something went wrong');

      await notifier.exerciseHooks(
        error: error,
        stackTrace: StackTrace.current,
      );

      expect(events, [
        'invalidateBuild',
        'setInitial',
        'setLoading:Loading:0.5',
        'setData:42',
        'setEmpty:Empty',
        'setError:$error',
        'refresh',
        'rebuild',
        'checkStaleness',
        'isStale',
      ]);
    });
  });
}