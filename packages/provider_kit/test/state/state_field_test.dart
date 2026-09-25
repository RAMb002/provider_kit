import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/state/state_field.dart';

void main() {
  group('StateField', () {
    test('stores the initial state', () {
      final field = StateField<String>('John');

      expect(field.state, 'John');
      expect(field.mounted, isTrue);

      field.dispose();
    });

    test('updates state', () {
      final field = StateField<String>('John');

      field.state = 'Ram';

      expect(field.state, 'Ram');

      field.dispose();
    });

    test('notifies listeners when state changes', () {
      final field = StateField<String>('John');
      var notificationCount = 0;

      field.addListener(() {
        notificationCount++;
      });

      field.state = 'Ram';

      expect(notificationCount, 1);
      expect(field.state, 'Ram');

      field.dispose();
    });

    test('does not notify listeners when state is unchanged', () {
      final field = StateField<String>('John');
      var notificationCount = 0;

      field.addListener(() {
        notificationCount++;
      });

      field.state = 'John';

      expect(notificationCount, 0);

      field.dispose();
    });

    test('notifies listeners for each distinct state change', () {
      final field = StateField<int>(0);
      var notificationCount = 0;

      field.addListener(() {
        notificationCount++;
      });

      field.state = 1;
      field.state = 2;
      field.state = 3;

      expect(notificationCount, 3);
      expect(field.state, 3);

      field.dispose();
    });

    test('mounted becomes false after dispose', () {
      final field = StateField<String>('John');

      expect(field.mounted, isTrue);

      field.dispose();

      expect(field.mounted, isFalse);
    });

    test('dispose is idempotent', () {
      final field = StateField<String>('John');

      field.dispose();
      field.dispose();

      expect(field.mounted, isFalse);
    });

    test('throws when state is changed after disposal', () {
      final field = StateField<String>('initial');

      field.dispose();

      expect(
        () => field.state = 'updated',
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
