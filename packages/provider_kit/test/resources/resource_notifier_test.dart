import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:rate_kit/rate_kit.dart';

void main() {
  group('ResourceNotifier', () {
    test('extends ChangeNotifier', () {
      final notifier = _TestResourceNotifier();

      expect(notifier, isA<ChangeNotifier>());

      notifier.dispose();
    });

    test('provides ProviderKit resource APIs', () {
      final notifier = _TestResourceNotifier();

      final field = notifier.testField;
      final mutation = notifier.testMutation;
      final mutationGroup = notifier.testMutationGroup;
      final debounce = notifier.testDebounce;
      final throttle = notifier.testThrottle;

      expect(field, isA<StateField<int>>());
      expect(mutation, isA<Mutation<bool>>());
      expect(mutationGroup, isA<MutationGroup<bool>>());
      expect(debounce, isA<Debounce>());
      expect(throttle, isA<Throttle>());

      notifier.dispose();
    });

    test('disposes owned resources when notifier is disposed', () {
      final notifier = _TestResourceNotifier();

      final field = notifier.testField;

      notifier.dispose();

      expect(
        () => field.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}

class _TestResourceNotifier extends ResourceNotifier {
  late final testField = field(0);
  late final testMutation = mutation<bool>();
  late final testMutationGroup = mutationGroup<bool>();
  late final testDebounce = debounce();
  late final testThrottle = throttle();
}