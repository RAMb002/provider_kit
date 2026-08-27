import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('ProviderKit', () {
    test('configures once and throws StateError when configured again', () {
      expect(
        () => ProviderKit.configure(),
        returnsNormally,
      );

      expect(
        () => ProviderKit.configure(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'ProviderKit has already been configured.',
          ),
        ),
      );
    });
  });
}