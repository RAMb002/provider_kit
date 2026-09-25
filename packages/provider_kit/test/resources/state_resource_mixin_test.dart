// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('StateResourcesMixin', () {
    group('resource ownership', () {
      testWidgets(
        'disposes all owned resources when state is disposed',
        (tester) async {
          final key = GlobalKey<_TestState>();

          await tester.pumpWidget(
            _TestWidget(key: key),
          );

          final state = key.currentState!;

          final stateField = state.field("initialState");

          final mutation = state.mutation<void>();

          final group = state.mutationGroup<void>();
          final groupedMutation = group('item');

          final debounce = state.debounce(
            duration: const Duration(seconds: 1),
          );

          final throttle = state.throttle(
            duration: const Duration(seconds: 1),
            leading: false,
            trailing: true,
          );

          var debounceCalls = 0;
          var throttleCalls = 0;

          debounce.run(() => debounceCalls++);
          throttle.run(() => throttleCalls++);

          expect(stateField.state, 'initialState');
          expect(stateField.mounted, isTrue);

          stateField.state = 'updatedState';

          expect(stateField.state, 'updatedState');

          expect(debounce.isPending(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          await tester.pumpWidget(const SizedBox());

          await tester.pump(const Duration(seconds: 2));

          expect(stateField.mounted, isFalse);

          expect(debounceCalls, 0);
          expect(throttleCalls, 0);

          expect(debounce.isPending(), isFalse);
          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          expect(mutation.mounted, isFalse);
          expect(groupedMutation.mounted, isFalse);

          await expectLater(
            mutation.run(() async {}),
            throwsA(isA<FlutterError>()),
          );

          await expectLater(
            groupedMutation.run(() async {}),
            throwsA(isA<FlutterError>()),
          );
        },
      );

      testWidgets(
        'disposes initialized shared debounce and throttle with state',
        (tester) async {
          final key = GlobalKey<_TestState>();

          await tester.pumpWidget(
            _TestWidget(key: key),
          );

          final state = key.currentState!;

          var debounceCalls = 0;
          var throttleCalls = 0;

          state.debounceRun(
            () => debounceCalls++,
            duration: const Duration(seconds: 1),
          );

          state.throttleRun(
            () => throttleCalls++,
          );

          // Default throttle is leading, so this runs immediately.
          expect(throttleCalls, 1);

          await tester.pumpWidget(const SizedBox());

          await tester.pump(const Duration(seconds: 2));

          expect(debounceCalls, 0);
          expect(throttleCalls, 1);

          expect(
            () => state.debounceRun(() {}),
            throwsA(isA<StateError>()),
          );

          expect(
            () => state.throttleRun(() {}),
            throwsA(isA<StateError>()),
          );
        },
      );

      testWidgets('disposes all created state fields with the notifier',
          (tester) async {
        final key = GlobalKey<_TestState>();

        await tester.pumpWidget(
          _TestWidget(key: key),
        );

        final state = key.currentState!;
        final firstField = state.field('first');
        final secondField = state.field(0);
        final thirdField = state.field(false);

        expect(firstField.mounted, isTrue);
        expect(secondField.mounted, isTrue);
        expect(thirdField.mounted, isTrue);

        await tester.pumpWidget(const SizedBox());

        expect(firstField.mounted, isFalse);
        expect(secondField.mounted, isFalse);
        expect(thirdField.mounted, isFalse);
      });
    });

    group('resource factories', () {
      testWidgets(
        'reject resource creation after state disposal',
        (tester) async {
          final key = GlobalKey<_TestState>();

          await tester.pumpWidget(
            _TestWidget(key: key),
          );

          final state = key.currentState!;

          await tester.pumpWidget(const SizedBox());

          expect(
            () => state.field('initialState'),
            throwsA(isA<StateError>()),
          );

          expect(
            () => state.mutation<void>(),
            throwsA(isA<StateError>()),
          );

          expect(
            () => state.mutationGroup<void>(),
            throwsA(isA<StateError>()),
          );

          expect(
            () => state.debounce(),
            throwsA(isA<StateError>()),
          );

          expect(
            () => state.throttle(),
            throwsA(isA<StateError>()),
          );
        },
      );

      testWidgets(
        'reject shared rate resource initialization after state disposal',
        (tester) async {
          final key = GlobalKey<_TestState>();

          await tester.pumpWidget(
            _TestWidget(key: key),
          );

          final state = key.currentState!;

          await tester.pumpWidget(const SizedBox());

          expect(
            () => state.debounceRun(() {}),
            throwsA(isA<StateError>()),
          );

          expect(
            () => state.throttleRun(() {}),
            throwsA(isA<StateError>()),
          );
        },
      );
    });

    group('shared rate resource forwarding', () {
      testWidgets(
        'forwards debounce key and duration',
        (tester) async {
          final key = GlobalKey<_TestState>();

          await tester.pumpWidget(
            _TestWidget(key: key),
          );

          final state = key.currentState!;

          var firstCalls = 0;
          var secondCalls = 0;

          state.debounceRun(
            () => firstCalls++,
            key: 'first',
            duration: const Duration(milliseconds: 100),
          );

          state.debounceRun(
            () => secondCalls++,
            key: 'second',
            duration: const Duration(milliseconds: 200),
          );

          await tester.pump(const Duration(milliseconds: 100));

          expect(firstCalls, 1);
          expect(secondCalls, 0);

          await tester.pump(const Duration(milliseconds: 100));

          expect(secondCalls, 1);

          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'forwards throttle keys',
        (tester) async {
          final key = GlobalKey<_TestState>();

          await tester.pumpWidget(
            _TestWidget(key: key),
          );

          final state = key.currentState!;

          var firstCalls = 0;
          var secondCalls = 0;

          state.throttleRun(
            () => firstCalls++,
            key: 'first',
          );

          state.throttleRun(
            () => secondCalls++,
            key: 'second',
          );

          expect(firstCalls, 1);
          expect(secondCalls, 1);

          await tester.pumpWidget(const SizedBox());
        },
      );
    });
  });
}

class _TestWidget extends StatefulWidget {
  const _TestWidget({super.key});

  @override
  State<_TestWidget> createState() => _TestState();
}

class _TestState extends State<_TestWidget>
    with StateResourcesMixin<_TestWidget> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
