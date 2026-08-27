import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

final class _TestObserver extends NotifierObserver {
  const _TestObserver();
}

void main() {
  group('ProviderKit observer configuration', () {
    test('accepts a custom observer', () {
      const observer = _TestObserver();

      expect(
        () => ProviderKit.configure(
          observer: observer,
        ),
        returnsNormally,
      );
    });
  });
}