import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';

typedef TwoStates = ({ViewState<String> first, ViewState<String> second});

void main() {
  group('ViewStateListener.multi', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    MultiStateProviders<ViewState<String>> singleProvider(
      ViewStateNotifier<String> provider,
    ) {
      return () => provider.watch;
    }

    MultiStateProviders<TwoStates> twoProviders(
      ViewStateNotifier<String> provider1,
      ViewStateNotifier<String> provider2,
    ) {
      return () => (first: provider1.watch, second: provider2.watch);
    }

    Widget buildListener({
      required MultiStateProviders<ViewState<String>> providers,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<ViewState<String>>? dataStateListener,
      ListenWhen<ViewState<String>>? listenWhen,
      bool callListenerOnInit = false,
      Widget? child,
    }) {
      return wrap(
        ViewStateListener.multi(
          providers: providers,
          initialStateListener: initialStateListener,
          loadingStateListener: loadingStateListener,
          emptyStateListener: emptyStateListener,
          errorStateListener: errorStateListener,
          dataStateListener: dataStateListener,
          listenWhen: listenWhen,
          callListenerOnInit: callListenerOnInit,
          child: child ?? const SizedBox(),
        ),
      );
    }

    Widget buildTwoProviderListener({
      required MultiStateProviders<TwoStates> providers,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<TwoStates>? dataStateListener,
      ListenWhen<TwoStates>? listenWhen,
      bool callListenerOnInit = false,
      Widget? child,
    }) {
      return wrap(
        ViewStateListener.multi(
          providers: providers,
          initialStateListener: initialStateListener,
          loadingStateListener: loadingStateListener,
          emptyStateListener: emptyStateListener,
          errorStateListener: errorStateListener,
          dataStateListener: dataStateListener,
          listenWhen: listenWhen,
          callListenerOnInit: callListenerOnInit,
          child: child ?? const SizedBox(),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Rendering & child
    // -------------------------------------------------------------------------

    testWidgets('renders the provided child', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          child: const SizedBox(key: Key('child')),
        ),
      );

      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets('throws AssertionError when child is not specified', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        ViewStateListener.multi(
          providers: singleProvider(provider),
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (AssertionError error) => error.message,
          'message',
          contains('child'),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // State-specific callback wiring
    // -------------------------------------------------------------------------

    testWidgets(
      'invokes the corresponding listener when the provider enters each state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );

        int initialCalls = 0;
        int loadingCalls = 0;
        int emptyCalls = 0;
        int errorCalls = 0;
        int dataCalls = 0;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            initialStateListener: () {
              initialCalls++;
            },
            loadingStateListener: (_, __) {
              loadingCalls++;
            },
            emptyStateListener: (_) {
              emptyCalls++;
            },
            errorStateListener: (_, __, ___, ____) {
              errorCalls++;
            },
            dataStateListener: (_) {
              dataCalls++;
            },
          ),
        );

        expect(dataCalls, 0);
        expect(initialCalls, 0);
        expect(loadingCalls, 0);
        expect(emptyCalls, 0);
        expect(errorCalls, 0);

        provider.emit(const InitialState<String>());
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 0);
        expect(emptyCalls, 0);
        expect(errorCalls, 0);
        expect(dataCalls, 0);

        provider.emit(const LoadingState<String>('Loading', 0.4));
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 0);
        expect(errorCalls, 0);
        expect(dataCalls, 0);

        provider.emit(const EmptyState<String>('Empty'));
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(errorCalls, 0);
        expect(dataCalls, 0);

        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(errorCalls, 1);
        expect(dataCalls, 0);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(errorCalls, 1);
        expect(dataCalls, 1);
      },
    );

    testWidgets(
      'errorStateListener receives ErrorState arguments unchanged and invokes retry callback',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        final Object expectedError = Exception('original error');
        final StackTrace expectedStackTrace = StackTrace.current;

        const ErrorInfo expectedErrorInfo = ErrorInfo(
          message: 'Mapped error',
          code: 'mapped_error',
        );

        bool retryCalled = false;

        ErrorInfo? capturedErrorInfo;
        Object? capturedError;
        StackTrace? capturedStackTrace;
        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            errorStateListener:
                (
                  ErrorInfo errorInfo,
                  Object error,
                  StackTrace stackTrace,
                  VoidCallback? onRetry,
                ) {
                  capturedErrorInfo = errorInfo;
                  capturedError = error;
                  capturedStackTrace = stackTrace;
                  capturedOnRetry = onRetry;
                },
          ),
        );

        provider.emit(
          ErrorState<String>(
            expectedError,
            expectedStackTrace,
            errorInfo: expectedErrorInfo,
            onRetry: () {
              retryCalled = true;
            },
          ),
        );

        await tester.pump();

        expect(capturedErrorInfo, same(expectedErrorInfo));
        expect(capturedError, same(expectedError));
        expect(capturedStackTrace, same(expectedStackTrace));
        expect(capturedOnRetry, isNotNull);

        capturedOnRetry!();

        expect(retryCalled, isTrue);
      },
    );

    testWidgets(
      'loadingStateListener receives loading message and nullable progress unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            loadingStateListener: (message, progress) {
              capturedMessage = message;
              capturedProgress = progress;
            },
          ),
        );

        provider.emit(const LoadingState<String>('Loading', 0.4));

        await tester.pump();

        expect(capturedMessage, 'Loading');
        expect(capturedProgress, 0.4);

        provider.emit(const LoadingState<String>('Loading without progress'));

        await tester.pump();

        expect(capturedMessage, 'Loading without progress');
        expect(capturedProgress, isNull);
      },
    );

    testWidgets(
      'emptyStateListener receives the EmptyState message unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            emptyStateListener: (message) {
              capturedMessage = message;
            },
          ),
        );

        provider.emit(const EmptyState<String>('Nothing found'));

        await tester.pump();

        expect(capturedMessage, 'Nothing found');
      },
    );

    testWidgets('dataStateListener receives the DataState unchanged', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      ViewState<String>? capturedState;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (state) {
            capturedState = state;
          },
        ),
      );

      const updatedState = DataState<String>('updated');

      provider.emit(updatedState);

      await tester.pump();

      expect(capturedState, same(updatedState));
    });

    // -------------------------------------------------------------------------
    // Initialization behavior
    // -------------------------------------------------------------------------

    testWidgets('does not call listeners on initialization by default', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      await tester.pump();

      expect(dataCalls, 0);
    });

    testWidgets(
      'callListenerOnInit invokes the listener with the current state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('Loading', 0.5),
        );

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            callListenerOnInit: true,
            loadingStateListener: (message, progress) {
              capturedMessage = message;
              capturedProgress = progress;
            },
          ),
        );

        await tester.pump();

        expect(capturedMessage, 'Loading');
        expect(capturedProgress, 0.5);
      },
    );

    // -------------------------------------------------------------------------
    // Dependency tracking
    // -------------------------------------------------------------------------

    testWidgets('subscribes to every provider accessed through watch', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(dataCalls, 1);

      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();

      expect(dataCalls, 2);
    });

    testWidgets(
      'subscribes only once when the same provider is watched multiple times',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataCalls = 0;

        await tester.pumpWidget(
          wrap(
            ViewStateListener.multi(
              providers: () => (first: provider.watch, second: provider.watch),
              dataStateListener: (_) {
                dataCalls++;
              },
              child: const SizedBox(),
            ),
          ),
        );

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        expect(dataCalls, 1);
      },
    );

    testWidgets(
      'throws StateError when a watched dependency is not a ViewStateNotifier',
      (tester) async {
        final field = StateField<String>('data');

        await tester.pumpWidget(
          wrap(
            ViewStateListener.multi(
              providers: () => field.watch,
              child: const SizedBox(),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('ViewStateNotifier'),
          ),
        );
      },
    );

    // -------------------------------------------------------------------------
    // Runtime dependency changes
    // -------------------------------------------------------------------------

    testWidgets('switches subscriptions when the watched provider changes', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      MultiStateProviders<ViewState<String>> providers = singleProvider(
        provider1,
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  ViewStateListener.multi(
                    providers: providers,
                    dataStateListener: (_) {
                      dataCalls++;
                    },
                    child: const SizedBox(),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        providers = singleProvider(provider2);
                      });
                    },
                    child: const Text('Switch'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(dataCalls, 1);

      await tester.tap(find.text('Switch'));
      await tester.pump();

      provider1.emit(const DataState<String>('one-after-switch'));

      await tester.pump();

      expect(dataCalls, 1);

      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();

      expect(dataCalls, 2);
    });

    testWidgets(
      'does not duplicate provider notifications after rebuilding with the same dependency',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataCalls = 0;

        Widget buildFrame() {
          return buildListener(
            providers: singleProvider(provider),
            dataStateListener: (_) {
              dataCalls++;
            },
          );
        }

        await tester.pumpWidget(buildFrame());

        provider.emit(const DataState<String>('first'));

        await tester.pump();

        expect(dataCalls, 1);

        await tester.pumpWidget(buildFrame());

        provider.emit(const DataState<String>('second'));

        await tester.pump();

        expect(dataCalls, 2);
      },
    );

    // -------------------------------------------------------------------------
    // Cleanup
    // -------------------------------------------------------------------------

    testWidgets('detaches provider listeners when the widget is removed', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_) {},
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // -------------------------------------------------------------------------
    // Diagnostics
    // -------------------------------------------------------------------------

    testWidgets(
      'debugFillProperties exposes MultiViewStateListener properties',
      (tester) async {
        final diagnostics = DiagnosticPropertiesBuilder();

        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        ViewStateListener.multi(
          providers: singleProvider(provider),
          initialStateListener: () {},
          loadingStateListener: (_, __) {},
          emptyStateListener: (_) {},
          errorStateListener: (_, __, ___, ____) {},
          dataStateListener: (_) {},
          listenWhen: (_, __) => true,
          callListenerOnInit: true,
          child: const SizedBox(),
        ).debugFillProperties(diagnostics);

        final description = diagnostics.properties
            .where((node) => !node.isFiltered(DiagnosticLevel.info))
            .map((node) => node.toString())
            .toList();

        expect(description.any((value) => value.contains('providers')), isTrue);

        expect(
          description.any((value) => value.contains('listenWhen')),
          isTrue,
        );

        expect(
          description.any(
            (value) =>
                value.contains('callListenerOnInit') && value.contains('true'),
          ),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('initialStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('loadingStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('emptyStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('errorStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('dataStateListener')),
          isTrue,
        );
      },
    );
  });
}
