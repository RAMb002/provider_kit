import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/resources/resource_owner.dart';

void main() {
  group('ResourceOwner', () {
    test('returns the exact owned resource and disposes it', () {
      final owner = ResourceOwner();
      final resource = _Resource();

      final returned = owner.own(
        resource,
        onDispose: (resource) => resource.disposed = true,
      );

      expect(identical(returned, resource), isTrue);
      expect(resource.disposed, isFalse);

      owner.dispose();

      expect(resource.disposed, isTrue);
    });

    test('disposes resources in reverse registration order', () {
      final owner = ResourceOwner();
      final disposalOrder = <String>[];

      owner.own(
        Object(),
        onDispose: (_) => disposalOrder.add('first'),
      );

      owner.own(
        Object(),
        onDispose: (_) => disposalOrder.add('second'),
      );

      owner.own(
        Object(),
        onDispose: (_) => disposalOrder.add('third'),
      );

      owner.dispose();

      expect(
        disposalOrder,
        ['third', 'second', 'first'],
      );
    });

    test('dispose is safe when no resources are owned', () {
      final owner = ResourceOwner();

      expect(owner.dispose, returnsNormally);
    });

    test('dispose is idempotent', () {
      final owner = ResourceOwner();
      var disposeCount = 0;

      owner.own(
        Object(),
        onDispose: (_) => disposeCount++,
      );

      owner.dispose();
      owner.dispose();

      expect(disposeCount, 1);
    });

    test(
      'continues disposing resources and rethrows the first encountered error',
      () {
        final owner = ResourceOwner();
        final disposalOrder = <String>[];

        final firstEncounteredError = StateError('first encountered error');
        final laterEncounteredError = StateError('later encountered error');

        owner.own(
          Object(),
          onDispose: (_) {
            disposalOrder.add('first');
            throw laterEncounteredError;
          },
        );

        owner.own(
          Object(),
          onDispose: (_) {
            disposalOrder.add('second');
          },
        );

        owner.own(
          Object(),
          onDispose: (_) {
            disposalOrder.add('third');
            throw firstEncounteredError;
          },
        );

        expect(
          owner.dispose,
          throwsA(same(firstEncounteredError)),
        );

        expect(
          disposalOrder,
          ['third', 'second', 'first'],
        );

        // All callbacks were processed despite the error.
        expect(owner.dispose, returnsNormally);
        expect(
          disposalOrder,
          ['third', 'second', 'first'],
        );
      },
    );

    test(
      'rethrows a disposal error with its original stack trace',
      () {
        final owner = ResourceOwner();
        final error = StateError('boom');
        late StackTrace originalStackTrace;

        owner.own(
          Object(),
          onDispose: (_) {
            try {
              throw error;
            } catch (_, stackTrace) {
              originalStackTrace = stackTrace;
              rethrow;
            }
          },
        );

        try {
          owner.dispose();
          fail('Expected dispose to throw.');
        } catch (caughtError, caughtStackTrace) {
          expect(caughtError, same(error));
          expect(caughtStackTrace, same(originalStackTrace));
        }
      },
    );

    test(
      'disposes a resource immediately and throws when owned after disposal',
      () {
        final owner = ResourceOwner();
        var resourceDisposed = false;

        owner.dispose();

        expect(
          () {
            owner.own(
              Object(),
              onDispose: (_) => resourceDisposed = true,
            );
          },
          throwsA(isA<StateError>()),
        );

        expect(resourceDisposed, isTrue);

        // The owner remains disposed after the failed registration.
        expect(
          () {
            owner.own(
              Object(),
              onDispose: (_) {},
            );
          },
          throwsA(isA<StateError>()),
        );

        expect(owner.dispose, returnsNormally);
      },
    );

    test(
      'propagates the disposal error when immediate disposal fails',
      () {
        final owner = ResourceOwner();
        final error = StateError('immediate disposal failed');

        owner.dispose();

        expect(
          () {
            owner.own(
              Object(),
              onDispose: (_) => throw error,
            );
          },
          throwsA(same(error)),
        );
      },
    );

    test(
      're-entrant ownership during disposal disposes immediately and throws',
      () {
        final owner = ResourceOwner();

        var reentrantResourceDisposed = false;
        var remainingResourceDisposed = false;

        owner.own(
          Object(),
          onDispose: (_) {
            expect(
              () {
                owner.own(
                  Object(),
                  onDispose: (_) {
                    reentrantResourceDisposed = true;
                  },
                );
              },
              throwsA(isA<StateError>()),
            );
          },
        );

        owner.own(
          Object(),
          onDispose: (_) {
            remainingResourceDisposed = true;
          },
        );

        expect(owner.dispose, returnsNormally);

        expect(reentrantResourceDisposed, isTrue);
        expect(remainingResourceDisposed, isTrue);
      },
    );

    test('re-entrant dispose does not run callbacks again', () {
      final owner = ResourceOwner();
      final order = <String>[];

      owner.own(
        Object(),
        onDispose: (_) {
          order.add('first');
          owner.dispose();
          order.add('first-after-reentrant');
        },
      );

      owner.own(
        Object(),
        onDispose: (_) => order.add('second'),
      );

      owner.dispose();

      expect(
        order,
        ['second', 'first', 'first-after-reentrant'],
      );
    });

    test('supports disposing a nested owner from a disposal callback', () {
      final outer = ResourceOwner();
      final inner = ResourceOwner();

      var innerDisposed = false;

      inner.own(
        Object(),
        onDispose: (_) => innerDisposed = true,
      );

      outer.own(
        Object(),
        onDispose: (_) => inner.dispose(),
      );

      outer.dispose();

      expect(innerDisposed, isTrue);
    });
  });
}

class _Resource {
  bool disposed = false;
}
