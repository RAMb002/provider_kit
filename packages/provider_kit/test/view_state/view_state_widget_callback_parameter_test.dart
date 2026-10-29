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
      Widget? child,
    }) {
      return wrap(
        ViewStateWidgetsProvider(
          initialStateBuilder: (_, __) => const SizedBox(),
          loadingStateBuilder: (_, __, ___) => const SizedBox(),
          emptyStateBuilder: (_, __, ___) => const SizedBox(),
          errorStateBuilder: (_, __, ___) => const SizedBox(),
          child: ViewStateConsumer<T>(
            listenable: provider,
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
            child: child,
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // InitialState
    // -------------------------------------------------------------------------

    testWidgets('forwards BuildContext to InitialState builder', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      BuildContext? capturedContext;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          initialBuilder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const InitialState<String>());
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
    });

    testWidgets('forwards BuildContext to InitialState listener', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      BuildContext? capturedContext;
      var listenerCalls = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          initialStateListener: (context) {
            capturedContext = context;
            listenerCalls++;
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const InitialState<String>());
      await tester.pump();

      expect(listenerCalls, 1);
      expect(capturedContext, isA<BuildContext>());
    });

    // -------------------------------------------------------------------------
    // LoadingState
    // -------------------------------------------------------------------------

    testWidgets('forwards BuildContext and LoadingStateDetails to builder', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      BuildContext? capturedContext;
      LoadingStateDetails? capturedDetails;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          loadingBuilder: (context, details) {
            capturedContext = context;
            capturedDetails = details;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const LoadingState<String>('Fetching profile', 0.75));
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
      expect(capturedDetails, isNotNull);
      expect(capturedDetails!.message, 'Fetching profile');
      expect(capturedDetails!.progress, 0.75);
    });

    testWidgets('forwards BuildContext and LoadingStateDetails to listener', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      BuildContext? capturedContext;
      LoadingStateDetails? capturedDetails;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          loadingStateListener: (context, details) {
            capturedContext = context;
            capturedDetails = details;
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const LoadingState<String>('Fetching profile', 0.75));
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
      expect(capturedDetails, isNotNull);
      expect(capturedDetails!.message, 'Fetching profile');
      expect(capturedDetails!.progress, 0.75);
    });

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
          loadingBuilder: (_, details) {
            capturedBuilderProgress = details.progress;
            return const SizedBox();
          },
          loadingStateListener: (_, details) {
            capturedListenerProgress = details.progress;
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const LoadingState<String>('Progress unavailable'));
      await tester.pump();

      expect(capturedBuilderProgress, isNull);
      expect(capturedListenerProgress, isNull);
    });

    // -------------------------------------------------------------------------
    // EmptyState
    // -------------------------------------------------------------------------

    testWidgets('forwards BuildContext and EmptyStateDetails to builder', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      BuildContext? capturedContext;
      EmptyStateDetails? capturedDetails;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          emptyBuilder: (context, details) {
            capturedContext = context;
            capturedDetails = details;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const EmptyState<String>('No results found'));
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
      expect(capturedDetails, isNotNull);
      expect(capturedDetails!.message, 'No results found');
    });

    testWidgets('forwards BuildContext and EmptyStateDetails to listener', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      BuildContext? capturedContext;
      EmptyStateDetails? capturedDetails;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          emptyStateListener: (context, details) {
            capturedContext = context;
            capturedDetails = details;
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const EmptyState<String>('No results found'));
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
      expect(capturedDetails, isNotNull);
      expect(capturedDetails!.message, 'No results found');
    });

    // -------------------------------------------------------------------------
    // ErrorState
    // -------------------------------------------------------------------------

    testWidgets('forwards BuildContext and ErrorStateDetails to builder', (
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

      var retryCalled = false;

      void expectedRetry() {
        retryCalled = true;
      }

      BuildContext? capturedContext;
      ErrorStateDetails? capturedDetails;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          errorBuilder: (context, details) {
            capturedContext = context;
            capturedDetails = details;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
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

      expect(capturedContext, isA<BuildContext>());
      expect(capturedDetails, isNotNull);

      expect(capturedDetails!.errorInfo, same(expectedErrorInfo));
      expect(capturedDetails!.error, same(expectedError));
      expect(capturedDetails!.stackTrace, same(expectedStackTrace));
      expect(capturedDetails!.onRetry, same(expectedRetry));

      capturedDetails!.onRetry!();

      expect(retryCalled, isTrue);
    });

    testWidgets('forwards BuildContext and ErrorStateDetails to listener', (
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

      var retryCalled = false;

      void expectedRetry() {
        retryCalled = true;
      }

      BuildContext? capturedContext;
      ErrorStateDetails? capturedDetails;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          errorStateListener: (context, details) {
            capturedContext = context;
            capturedDetails = details;
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
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

      expect(capturedContext, isA<BuildContext>());
      expect(capturedDetails, isNotNull);

      expect(capturedDetails!.errorInfo, same(expectedErrorInfo));
      expect(capturedDetails!.error, same(expectedError));
      expect(capturedDetails!.stackTrace, same(expectedStackTrace));
      expect(capturedDetails!.onRetry, same(expectedRetry));

      capturedDetails!.onRetry!();

      expect(retryCalled, isTrue);
    });

    // -------------------------------------------------------------------------
    // DataState
    // -------------------------------------------------------------------------

    testWidgets('forwards BuildContext, data, and child to DataState builder', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      const child = SizedBox(key: Key('prebuilt-child'));

      BuildContext? capturedContext;
      String? capturedData;
      Widget? capturedChild;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          child: child,
          dataBuilder: (context, data, childWidget) {
            capturedContext = context;
            capturedData = data;
            capturedChild = childWidget;
            return const SizedBox();
          },
        ),
      );

      provider.emit(const DataState<String>('updated'));
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
      expect(capturedData, 'updated');
      expect(capturedChild, same(child));
    });

    testWidgets('forwards BuildContext and data to DataState listener', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      BuildContext? capturedContext;
      String? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataStateListener: (context, data) {
            capturedContext = context;
            capturedData = data;
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const DataState<String>('updated'));
      await tester.pump();

      expect(capturedContext, isA<BuildContext>());
      expect(capturedData, 'updated');
    });
  });
}
