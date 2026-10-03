import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../shared/mocks/view_state_notifiers.dart';

void main() {
  group('ViewStateConsumer callback parameters', () {
    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    Widget buildConsumer<T>({
      required ViewStateNotifier<T> provider,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<T> dataBuilder,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<T>? dataStateListener,
      bool isSliver = false,
    }) {
      return wrap(
        ViewStateWidgetsProvider(
          initialStateBuilder: (_) => const SizedBox(),
          loadingStateBuilder: (_, __, ___) => const SizedBox(),
          emptyStateBuilder: (_, __) => const SizedBox(),
          errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
          child: ViewStateConsumer<T>(
            provider: provider,
            initialBuilder: initialBuilder,
            loadingBuilder: loadingBuilder,
            emptyBuilder: emptyBuilder,
            errorBuilder: errorBuilder,
            dataBuilder: dataBuilder,
            initialStateListener: initialStateListener,
            loadingStateListener: loadingStateListener,
            emptyStateListener: emptyStateListener,
            errorStateListener: errorStateListener,
            dataStateListener: dataStateListener,
            isSliver: isSliver,
          ),
        ),
      );
    }

    // ---------------------------------------------------------------------------
    // InitialState
    // ---------------------------------------------------------------------------

    testWidgets('forwards InitialState builder parameter correctly', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          initialBuilder: (isSliver) {
            capturedIsSliver = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      provider.emit(const InitialState<String>());
      await tester.pump();

      expect(capturedIsSliver, isA<bool>());
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('invokes InitialState listener without parameters', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      int listenerCalls = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          initialStateListener: () {
            listenerCalls++;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider.emit(const InitialState<String>());
      await tester.pump();

      expect(listenerCalls, 1);
    });

    // ---------------------------------------------------------------------------
    // LoadingState
    // ---------------------------------------------------------------------------

    testWidgets(
      'forwards LoadingState builder parameters in the correct order',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;
        double? capturedProgress;
        bool? capturedIsSliver;

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            loadingBuilder: (message, progress, isSliver) {
              capturedMessage = message;
              capturedProgress = progress;
              capturedIsSliver = isSliver;

              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
            isSliver: true,
          ),
        );

        provider.emit(const LoadingState<String>('Fetching profile', 0.75));

        await tester.pump();

        // 1. String
        expect(capturedMessage, isA<String>());
        expect(capturedMessage, 'Fetching profile');

        // 2. double?
        expect(capturedProgress, isA<double>());
        expect(capturedProgress, 0.75);

        // 3. bool
        expect(capturedIsSliver, isA<bool>());
        expect(capturedIsSliver, isTrue);
      },
    );

    testWidgets(
      'forwards LoadingState listener parameters in the correct order',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            loadingStateListener: (message, progress) {
              capturedMessage = message;
              capturedProgress = progress;
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.emit(const LoadingState<String>('Fetching profile', 0.75));

        await tester.pump();

        // 1. String
        expect(capturedMessage, isA<String>());
        expect(capturedMessage, 'Fetching profile');

        // 2. double?
        expect(capturedProgress, isA<double>());
        expect(capturedProgress, 0.75);
      },
    );

    testWidgets('forwards null LoadingState progress unchanged', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      double? capturedBuilderProgress;
      double? capturedListenerProgress;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          loadingBuilder: (_, progress, _) {
            capturedBuilderProgress = progress;
            return const SizedBox();
          },
          loadingStateListener: (_, progress) {
            capturedListenerProgress = progress;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider.emit(const LoadingState<String>('Progress unavailable'));

      await tester.pump();

      expect(capturedBuilderProgress, isNull);
      expect(capturedListenerProgress, isNull);
    });

    // ---------------------------------------------------------------------------
    // EmptyState
    // ---------------------------------------------------------------------------

    testWidgets('forwards EmptyState builder parameters in the correct order', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      String? capturedMessage;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          emptyBuilder: (message, isSliver) {
            capturedMessage = message;
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      provider.emit(const EmptyState<String>('No results found'));

      await tester.pump();

      // 1. String
      expect(capturedMessage, isA<String>());
      expect(capturedMessage, 'No results found');

      // 2. bool
      expect(capturedIsSliver, isA<bool>());
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('forwards EmptyState listener parameter correctly', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      String? capturedMessage;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          emptyStateListener: (message) {
            capturedMessage = message;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider.emit(const EmptyState<String>('No results found'));

      await tester.pump();

      expect(capturedMessage, isA<String>());
      expect(capturedMessage, 'No results found');
    });

    // ---------------------------------------------------------------------------
    // ErrorState
    // ---------------------------------------------------------------------------

    testWidgets('forwards ErrorState builder parameters in the correct order', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      const expectedErrorInfo = ErrorInfo(
        message: 'Mapped network error',
        code: 'network_error',
      );

      final expectedError = StateError('Request failed');
      final expectedStackTrace = StackTrace.current;

      bool retryCalled = false;

      void expectedRetry() {
        retryCalled = true;
      }

      ErrorInfo? capturedErrorInfo;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      VoidCallback? capturedRetry;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
            capturedErrorInfo = errorInfo;
            capturedError = error;
            capturedStackTrace = stackTrace;
            capturedRetry = onRetry;
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      provider.emit(
        ErrorState<String>(
          expectedError,
          expectedStackTrace,
          errorInfo: expectedErrorInfo,
          onRetry: expectedRetry,
        ),
      );

      await tester.pump();

      // 1. ErrorInfo
      expect(capturedErrorInfo, isA<ErrorInfo>());
      expect(capturedErrorInfo, same(expectedErrorInfo));

      // 2. Object
      expect(capturedError, isA<Object>());
      expect(capturedError, isA<StateError>());
      expect(capturedError, same(expectedError));

      // 3. StackTrace
      expect(capturedStackTrace, isA<StackTrace>());
      expect(capturedStackTrace, same(expectedStackTrace));

      // 4. VoidCallback?
      expect(capturedRetry, isNotNull);
      expect(capturedRetry, same(expectedRetry));

      // 5. bool
      expect(capturedIsSliver, isA<bool>());
      expect(capturedIsSliver, isTrue);

      capturedRetry!();

      expect(retryCalled, isTrue);
    });

    testWidgets(
      'forwards ErrorState listener parameters in the correct order',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        const expectedErrorInfo = ErrorInfo(
          message: 'Mapped network error',
          code: 'network_error',
        );

        final expectedError = StateError('Request failed');
        final expectedStackTrace = StackTrace.current;

        bool retryCalled = false;

        void expectedRetry() {
          retryCalled = true;
        }

        ErrorInfo? capturedErrorInfo;
        Object? capturedError;
        StackTrace? capturedStackTrace;
        VoidCallback? capturedRetry;

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            errorStateListener: (errorInfo, error, stackTrace, onRetry) {
              capturedErrorInfo = errorInfo;
              capturedError = error;
              capturedStackTrace = stackTrace;
              capturedRetry = onRetry;
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.emit(
          ErrorState<String>(
            expectedError,
            expectedStackTrace,
            errorInfo: expectedErrorInfo,
            onRetry: expectedRetry,
          ),
        );

        await tester.pump();

        // 1. ErrorInfo
        expect(capturedErrorInfo, isA<ErrorInfo>());
        expect(capturedErrorInfo, same(expectedErrorInfo));

        // 2. Object
        expect(capturedError, isA<Object>());
        expect(capturedError, isA<StateError>());
        expect(capturedError, same(expectedError));

        // 3. StackTrace
        expect(capturedStackTrace, isA<StackTrace>());
        expect(capturedStackTrace, same(expectedStackTrace));

        // 4. VoidCallback?
        expect(capturedRetry, isNotNull);
        expect(capturedRetry, same(expectedRetry));

        capturedRetry!();

        expect(retryCalled, isTrue);
      },
    );

    // ---------------------------------------------------------------------------
    // DataState
    // ---------------------------------------------------------------------------

    testWidgets('forwards DataState builder parameter correctly', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      String? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (data) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      provider.emit(const DataState<String>('updated'));

      await tester.pump();

      expect(capturedData, isA<String>());
      expect(capturedData, 'updated');
    });

    testWidgets('forwards DataState listener parameter correctly', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      String? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataStateListener: (data) {
            capturedData = data;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider.emit(const DataState<String>('updated'));

      await tester.pump();

      expect(capturedData, isA<String>());
      expect(capturedData, 'updated');
    });
  });
}
