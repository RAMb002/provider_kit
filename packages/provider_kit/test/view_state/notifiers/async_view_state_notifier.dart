import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

class _TestAsyncNotifier extends AsyncViewStateNotifier<int> {
  _TestAsyncNotifier(this.events);

  final List<String> events;

  @override
  void onInitialize() {
    events.add('initialize');
    super.onInitialize();
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> rebuild() async {}

  @override
  bool Function() checkStaleness() =>
      () => false;
}

void main() {
  group('AsyncViewStateNotifier', () {
    test('calls onInitialize after construction', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      events.add('constructed');
      await Future<void>.delayed(Duration.zero);
      expect(events, ['constructed', 'initialize']);
      notifier.dispose();
    });

    test('calls onInitialize only once', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      await Future<void>.delayed(Duration.zero);
      expect(events.where((event) => event == 'initialize').length, 1);
      notifier.dispose();
    });

    test('does not call onInitialize after disposal', () async {
      final events = <String>[];
      final notifier = _TestAsyncNotifier(events);
      notifier.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });
  });
}
