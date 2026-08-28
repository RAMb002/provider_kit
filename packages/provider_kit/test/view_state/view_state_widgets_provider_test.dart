import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

// -----------------------------------------------------------------------------
// Dummy builders (defined once at top-level for reference equality tests)
// -----------------------------------------------------------------------------

Widget dummyInitialBuilder(bool isSliver) =>
    const SizedBox(key: Key('initial'));

Widget dummyLoadingBuilder(String? message, double? progress, bool isSliver) =>
    const SizedBox(key: Key('loading'));

Widget dummyEmptyBuilder(String? message, bool isSliver) =>
    const SizedBox(key: Key('empty'));

Widget dummyErrorBuilder(
  ErrorInfo errorInfo,
  Object error,
  StackTrace? stackTrace,
  VoidCallback? onRetry,
  bool isSliver,
) =>
    const SizedBox(key: Key('error'));

// Alternative builders for override testing
Widget customInitialBuilder(bool isSliver) =>
    const SizedBox(key: Key('custom_initial'));

Widget customLoadingBuilder(String? message, double? progress, bool isSliver) =>
    const SizedBox(key: Key('custom_loading'));

// -----------------------------------------------------------------------------
// Test Suite
// -----------------------------------------------------------------------------

void main() {
  group('ViewStateWidgetsProvider Tests', () {
    // -------------------------------------------------------------------------
    // 1. Stores builders correctly
    // -------------------------------------------------------------------------
    testWidgets('stores all builders provided in standard constructor',
        (tester) async {
      const key = Key('provider');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            key: key,
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: SizedBox(),
          ),
        ),
      );

      final provider = tester.widget<ViewStateWidgetsProvider>(
        find.byKey(key),
      );

      expect(provider.initialStateBuilder, equals(dummyInitialBuilder));
      expect(provider.loadingStateBuilder, equals(dummyLoadingBuilder));
      expect(provider.emptyStateBuilder, equals(dummyEmptyBuilder));
      expect(provider.errorStateBuilder, equals(dummyErrorBuilder));
    });

    // -------------------------------------------------------------------------
    // 2. maybeOf behavior
    // -------------------------------------------------------------------------
    testWidgets('maybeOf returns the provider when present in tree',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (context) {
                final result = ViewStateWidgetsProvider.maybeOf(context);
                expect(result, isNotNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('maybeOf returns null when provider is missing from tree',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              final result = ViewStateWidgetsProvider.maybeOf(context);
              expect(result, isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // 3. of behavior
    // -------------------------------------------------------------------------
    testWidgets('of returns the provider when present in tree', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (context) {
                final result = ViewStateWidgetsProvider.of(context);
                expect(result, isNotNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('of throws AssertionError when provider is missing from tree',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              expect(
                () => ViewStateWidgetsProvider.of(context),
                throwsAssertionError,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // 4. updateShouldNotify behavior
    // -------------------------------------------------------------------------
    test('updateShouldNotify returns false when all builders remain identical',
        () {
      const provider1 = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        child: SizedBox(),
      );

      const provider2 = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        child: SizedBox(),
      );

      expect(provider2.updateShouldNotify(provider1), isFalse);
    });

    test('updateShouldNotify returns true when ANY builder changes', () {
      const providerBase = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        child: SizedBox(),
      );

      const providerChangedInitial = ViewStateWidgetsProvider(
        initialStateBuilder: customInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        child: SizedBox(),
      );

      const providerChangedLoading = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: customLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        child: SizedBox(),
      );

      expect(providerChangedInitial.updateShouldNotify(providerBase), isTrue);
      expect(providerChangedLoading.updateShouldNotify(providerBase), isTrue);
    });

    // -------------------------------------------------------------------------
    // 5. ViewStateWidgetsProvider.override Subtree Scoping Tests
    // -------------------------------------------------------------------------
    testWidgets(
        'override selectively updates specified builders while inheriting unpassed ones',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (context) {
                return ViewStateWidgetsProvider.override(
                  context: context,
                  loadingStateBuilder:
                      customLoadingBuilder, // Override ONLY loading
                  child: Builder(
                    builder: (nestedContext) {
                      final provider =
                          ViewStateWidgetsProvider.of(nestedContext);

                      // Inherited from parent root provider
                      expect(provider.initialStateBuilder,
                          equals(dummyInitialBuilder));
                      expect(provider.emptyStateBuilder,
                          equals(dummyEmptyBuilder));
                      expect(provider.errorStateBuilder,
                          equals(dummyErrorBuilder));

                      // Overridden for this subtree
                      expect(provider.loadingStateBuilder,
                          equals(customLoadingBuilder));

                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    });

    testWidgets('override leaves parent provider untouched outside the subtree',
        (tester) async {
      late BuildContext parentScopeContext;
      late BuildContext childScopeContext;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (context) {
                parentScopeContext = context;
                return ViewStateWidgetsProvider.override(
                  context: context,
                  initialStateBuilder: customInitialBuilder,
                  child: Builder(
                    builder: (nestedContext) {
                      childScopeContext = nestedContext;
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Child subtree gets custom overridden builder
      expect(
        ViewStateWidgetsProvider.of(childScopeContext).initialStateBuilder,
        equals(customInitialBuilder),
      );

      // Parent scope outside subtree retains base builder
      expect(
        ViewStateWidgetsProvider.of(parentScopeContext).initialStateBuilder,
        equals(dummyInitialBuilder),
      );
    });

    // -------------------------------------------------------------------------
    // 6. ContextX Extension Getters
    // -------------------------------------------------------------------------
    testWidgets(
        'ContextX extension getters return correct builders from context',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (context) {
                expect(context.initialStateWidget, equals(dummyInitialBuilder));
                expect(context.loadingStateWidget, equals(dummyLoadingBuilder));
                expect(context.emptyStateWidget, equals(dummyEmptyBuilder));
                expect(context.errorStateWidget, equals(dummyErrorBuilder));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
        'ContextX extension getters reflect subtree overrides accurately',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (context) {
                return ViewStateWidgetsProvider.override(
                  context: context,
                  initialStateBuilder: customInitialBuilder,
                  loadingStateBuilder: customLoadingBuilder,
                  child: Builder(
                    builder: (nestedContext) {
                      expect(nestedContext.initialStateWidget,
                          equals(customInitialBuilder));
                      expect(nestedContext.loadingStateWidget,
                          equals(customLoadingBuilder));
                      expect(nestedContext.emptyStateWidget,
                          equals(dummyEmptyBuilder));
                      expect(nestedContext.errorStateWidget,
                          equals(dummyErrorBuilder));
                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // 7. Multi-level / 3-Tier Deep Override Tests
    // -------------------------------------------------------------------------
    testWidgets(
        '3-tier deep override correctly cascades changes down multiple levels and leaves parent scopes unchanged',
        (tester) async {
      Widget level3Initial(bool isSliver) =>
          const SizedBox(key: Key('level3_initial'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            // Level 1 (Root)
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            child: Builder(
              builder: (level1Context) {
                return ViewStateWidgetsProvider.override(
                  // Level 2 (Overrides Loading)
                  context: level1Context,
                  loadingStateBuilder: customLoadingBuilder,
                  child: Builder(
                    builder: (level2Context) {
                      return ViewStateWidgetsProvider.override(
                        // Level 3 (Overrides Initial)
                        context: level2Context,
                        initialStateBuilder: level3Initial,
                        child: Builder(
                          builder: (level3Context) {
                            // --- 1. LEVEL 3 SCOPE CHECKS ---
                            final level3Provider =
                                ViewStateWidgetsProvider.of(level3Context);

                            // Level 3 custom override
                            expect(level3Provider.initialStateBuilder,
                                equals(level3Initial));
                            // Level 2 custom override (inherited)
                            expect(level3Provider.loadingStateBuilder,
                                equals(customLoadingBuilder));
                            // Level 1 root defaults (inherited)
                            expect(level3Provider.emptyStateBuilder,
                                equals(dummyEmptyBuilder));
                            expect(level3Provider.errorStateBuilder,
                                equals(dummyErrorBuilder));

                            // --- 2. LEVEL 2 SCOPE CHECKS (Must NOT have Level 3's initial override) ---
                            final level2Provider =
                                ViewStateWidgetsProvider.of(level2Context);

                            expect(
                                level2Provider.initialStateBuilder,
                                equals(
                                    dummyInitialBuilder)); // Still root default
                            expect(
                                level2Provider.loadingStateBuilder,
                                equals(
                                    customLoadingBuilder)); // Level 2 override
                            expect(level2Provider.emptyStateBuilder,
                                equals(dummyEmptyBuilder));
                            expect(level2Provider.errorStateBuilder,
                                equals(dummyErrorBuilder));

                            // --- 3. LEVEL 1 ROOT SCOPE CHECKS (Must be 100% pristine) ---
                            final level1Provider =
                                ViewStateWidgetsProvider.of(level1Context);

                            expect(level1Provider.initialStateBuilder,
                                equals(dummyInitialBuilder));
                            expect(level1Provider.loadingStateBuilder,
                                equals(dummyLoadingBuilder));
                            expect(level1Provider.emptyStateBuilder,
                                equals(dummyEmptyBuilder));
                            expect(level1Provider.errorStateBuilder,
                                equals(dummyErrorBuilder));

                            return const SizedBox();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
        'wrapping a sub-Navigator with override applies custom builders to all routes inside it',
        (tester) async {
      await tester.pumpWidget(
        ViewStateWidgetsProvider(
          initialStateBuilder: dummyInitialBuilder,
          loadingStateBuilder: dummyLoadingBuilder,
          emptyStateBuilder: dummyEmptyBuilder,
          errorStateBuilder: dummyErrorBuilder,
          child: MaterialApp(
            home: Builder(
              builder: (outerContext) {
                // Scope a specific sub-flow / sub-navigator
                return ViewStateWidgetsProvider.override(
                  context: outerContext,
                  loadingStateBuilder: customLoadingBuilder,
                  child: SizedBox(
                    height: 400,
                    width: 400,
                    child: Navigator(
                      onGenerateRoute: (settings) {
                        return MaterialPageRoute(
                          builder: (subRouteContext) {
                            final provider =
                                ViewStateWidgetsProvider.of(subRouteContext);
                            return Text(
                              provider.loadingStateBuilder ==
                                      customLoadingBuilder
                                  ? 'Sub-Navigator Overridden'
                                  : 'Sub-Navigator Default',
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Route pushed inside sub-navigator inherits the override placed above the sub-navigator
      expect(find.text('Sub-Navigator Overridden'), findsOneWidget);
    });
  });
}
