import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

// -----------------------------------------------------------------------------
// Dummy builders (defined once at top-level for reference equality tests)
// -----------------------------------------------------------------------------

Widget dummyInitialBuilder(BuildContext context, bool isSliver) =>
    const SizedBox(key: Key('initial'));

Widget dummyLoadingBuilder(
  BuildContext context,
  LoadingStateDetails details,
  bool isSliver,
) => const SizedBox(key: Key('loading'));

Widget dummyEmptyBuilder(
  BuildContext context,
  EmptyStateDetails details,
  bool isSliver,
) => const SizedBox(key: Key('empty'));

Widget dummyErrorBuilder(
  BuildContext context,
  ErrorStateDetails details,
  bool isSliver,
) => const SizedBox(key: Key('error'));

String? dummyMessageResolver(BuildContext context, String message) =>
    'dummy:$message';

// Alternative builders for override testing
Widget customInitialBuilder(BuildContext context, bool isSliver) =>
    const SizedBox(key: Key('custom_initial'));

Widget customLoadingBuilder(
  BuildContext context,
  LoadingStateDetails details,
  bool isSliver,
) => const SizedBox(key: Key('custom_loading'));

Widget customEmptyBuilder(
  BuildContext context,
  EmptyStateDetails details,
  bool isSliver,
) => const SizedBox(key: Key('custom_empty'));

Widget customErrorBuilder(
  BuildContext context,
  ErrorStateDetails details,
  bool isSliver,
) => const SizedBox(key: Key('custom_error'));

String? customMessageResolver(BuildContext context, String message) =>
    'custom:$message';

String? unhandledMessageResolver(BuildContext context, String message) => null;

String? emptyStringMessageResolver(BuildContext context, String message) => '';
// -----------------------------------------------------------------------------
// Test Suite
// -----------------------------------------------------------------------------

void main() {
  group('ViewStateWidgetsProvider Tests', () {
    // -------------------------------------------------------------------------
    // 1. Stores builders correctly
    // -------------------------------------------------------------------------
    testWidgets('stores all builders provided in standard constructor', (
      tester,
    ) async {
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
            messageResolver: dummyMessageResolver,
            child: SizedBox(),
          ),
        ),
      );

      final provider = tester.widget<ViewStateWidgetsProvider>(find.byKey(key));

      expect(provider.initialStateBuilder, equals(dummyInitialBuilder));
      expect(provider.loadingStateBuilder, equals(dummyLoadingBuilder));
      expect(provider.emptyStateBuilder, equals(dummyEmptyBuilder));
      expect(provider.errorStateBuilder, equals(dummyErrorBuilder));
      expect(provider.messageResolver, equals(dummyMessageResolver));
    });

    // -------------------------------------------------------------------------
    // 2. maybeOf behavior
    // -------------------------------------------------------------------------
    testWidgets('maybeOf returns the provider when present in tree', (
      tester,
    ) async {
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

    testWidgets('maybeOf returns null when provider is missing from tree', (
      tester,
    ) async {
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

    testWidgets('of throws AssertionError when provider is missing from tree', (
      tester,
    ) async {
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
    test(
      'updateShouldNotify returns false when all builders remain identical',
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
      },
    );

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

      const providerChangedEmpty = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: customEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        child: SizedBox(),
      );

      const providerChangedError = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: customErrorBuilder,
        child: SizedBox(),
      );

      expect(providerChangedEmpty.updateShouldNotify(providerBase), isTrue);
      expect(providerChangedError.updateShouldNotify(providerBase), isTrue);

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
                        final provider = ViewStateWidgetsProvider.of(
                          nestedContext,
                        );

                        // Inherited from parent root provider
                        expect(
                          provider.initialStateBuilder,
                          equals(dummyInitialBuilder),
                        );
                        expect(
                          provider.emptyStateBuilder,
                          equals(dummyEmptyBuilder),
                        );
                        expect(
                          provider.errorStateBuilder,
                          equals(dummyErrorBuilder),
                        );

                        // Overridden for this subtree
                        expect(
                          provider.loadingStateBuilder,
                          equals(customLoadingBuilder),
                        );

                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets(
      'override leaves parent provider untouched outside the subtree',
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
      },
    );

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
                  expect(
                    context.initialStateWidget,
                    equals(dummyInitialBuilder),
                  );
                  expect(
                    context.loadingStateWidget,
                    equals(dummyLoadingBuilder),
                  );
                  expect(context.emptyStateWidget, equals(dummyEmptyBuilder));
                  expect(context.errorStateWidget, equals(dummyErrorBuilder));
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      },
    );

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
                        expect(
                          nestedContext.initialStateWidget,
                          equals(customInitialBuilder),
                        );
                        expect(
                          nestedContext.loadingStateWidget,
                          equals(customLoadingBuilder),
                        );
                        expect(
                          nestedContext.emptyStateWidget,
                          equals(dummyEmptyBuilder),
                        );
                        expect(
                          nestedContext.errorStateWidget,
                          equals(dummyErrorBuilder),
                        );
                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    // -------------------------------------------------------------------------
    // 7. Multi-level / 3-Tier Deep Override Tests
    // -------------------------------------------------------------------------
    testWidgets(
      '3-tier deep override correctly cascades changes down multiple levels and leaves parent scopes unchanged',
      (tester) async {
        Widget level3Initial(BuildContext context, bool isSliver) =>
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
                              expect(
                                level3Provider.initialStateBuilder,
                                equals(level3Initial),
                              );
                              // Level 2 custom override (inherited)
                              expect(
                                level3Provider.loadingStateBuilder,
                                equals(customLoadingBuilder),
                              );
                              // Level 1 root defaults (inherited)
                              expect(
                                level3Provider.emptyStateBuilder,
                                equals(dummyEmptyBuilder),
                              );
                              expect(
                                level3Provider.errorStateBuilder,
                                equals(dummyErrorBuilder),
                              );

                              // --- 2. LEVEL 2 SCOPE CHECKS (Must NOT have Level 3's initial override) ---
                              final level2Provider =
                                  ViewStateWidgetsProvider.of(level2Context);

                              expect(
                                level2Provider.initialStateBuilder,
                                equals(dummyInitialBuilder),
                              ); // Still root default
                              expect(
                                level2Provider.loadingStateBuilder,
                                equals(customLoadingBuilder),
                              ); // Level 2 override
                              expect(
                                level2Provider.emptyStateBuilder,
                                equals(dummyEmptyBuilder),
                              );
                              expect(
                                level2Provider.errorStateBuilder,
                                equals(dummyErrorBuilder),
                              );

                              // --- 3. LEVEL 1 ROOT SCOPE CHECKS (Must be 100% pristine) ---
                              final level1Provider =
                                  ViewStateWidgetsProvider.of(level1Context);

                              expect(
                                level1Provider.initialStateBuilder,
                                equals(dummyInitialBuilder),
                              );
                              expect(
                                level1Provider.loadingStateBuilder,
                                equals(dummyLoadingBuilder),
                              );
                              expect(
                                level1Provider.emptyStateBuilder,
                                equals(dummyEmptyBuilder),
                              );
                              expect(
                                level1Provider.errorStateBuilder,
                                equals(dummyErrorBuilder),
                              );

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
      },
    );

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
                              final provider = ViewStateWidgetsProvider.of(
                                subRouteContext,
                              );
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
      },
    );

    // -------------------------------------------------------------------------
    // 8. Message resolver: updateShouldNotify
    // -------------------------------------------------------------------------

    test(
      'updateShouldNotify returns false when message resolver is unchanged',
      () {
        const previous = ViewStateWidgetsProvider(
          initialStateBuilder: dummyInitialBuilder,
          loadingStateBuilder: dummyLoadingBuilder,
          emptyStateBuilder: dummyEmptyBuilder,
          errorStateBuilder: dummyErrorBuilder,
          messageResolver: dummyMessageResolver,
          child: SizedBox(),
        );

        const current = ViewStateWidgetsProvider(
          initialStateBuilder: dummyInitialBuilder,
          loadingStateBuilder: dummyLoadingBuilder,
          emptyStateBuilder: dummyEmptyBuilder,
          errorStateBuilder: dummyErrorBuilder,
          messageResolver: dummyMessageResolver,
          child: SizedBox(),
        );

        expect(current.updateShouldNotify(previous), isFalse);
      },
    );

    test('updateShouldNotify returns true when message resolver changes', () {
      const previous = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        messageResolver: dummyMessageResolver,
        child: SizedBox(),
      );

      const current = ViewStateWidgetsProvider(
        initialStateBuilder: dummyInitialBuilder,
        loadingStateBuilder: dummyLoadingBuilder,
        emptyStateBuilder: dummyEmptyBuilder,
        errorStateBuilder: dummyErrorBuilder,
        messageResolver: customMessageResolver,
        child: SizedBox(),
      );

      expect(current.updateShouldNotify(previous), isTrue);
    });

    // -------------------------------------------------------------------------
    // 9. Message resolver: local resolver precedence
    // -------------------------------------------------------------------------

    testWidgets('local resolver takes precedence over parent resolver', (
      tester,
    ) async {
      String? resolvedMessage;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            messageResolver: dummyMessageResolver,
            child: Builder(
              builder: (context) {
                return ViewStateWidgetsProvider.override(
                  context: context,
                  messageResolver: customMessageResolver,
                  child: Builder(
                    builder: (nestedContext) {
                      resolvedMessage = nestedContext.resolveViewStateMessage(
                        'profile.title',
                      );

                      return const SizedBox();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(resolvedMessage, 'custom:profile.title');
    });

    // -------------------------------------------------------------------------
    // 10. Message resolver: parent fallback
    // -------------------------------------------------------------------------

    testWidgets(
      'local resolver returning null falls through to parent resolver',
      (tester) async {
        String? resolvedMessage;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateWidgetsProvider(
              initialStateBuilder: dummyInitialBuilder,
              loadingStateBuilder: dummyLoadingBuilder,
              emptyStateBuilder: dummyEmptyBuilder,
              errorStateBuilder: dummyErrorBuilder,
              messageResolver: dummyMessageResolver,
              child: Builder(
                builder: (context) {
                  return ViewStateWidgetsProvider.override(
                    context: context,
                    messageResolver: unhandledMessageResolver,
                    child: Builder(
                      builder: (nestedContext) {
                        resolvedMessage = nestedContext.resolveViewStateMessage(
                          'profile.title',
                        );

                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(resolvedMessage, 'dummy:profile.title');
      },
    );

    testWidgets(
      'override without a local resolver falls through to parent resolver',
      (tester) async {
        String? resolvedMessage;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateWidgetsProvider(
              initialStateBuilder: dummyInitialBuilder,
              loadingStateBuilder: dummyLoadingBuilder,
              emptyStateBuilder: dummyEmptyBuilder,
              errorStateBuilder: dummyErrorBuilder,
              messageResolver: dummyMessageResolver,
              child: Builder(
                builder: (context) {
                  return ViewStateWidgetsProvider.override(
                    context: context,
                    child: Builder(
                      builder: (nestedContext) {
                        resolvedMessage = nestedContext.resolveViewStateMessage(
                          'profile.title',
                        );

                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(resolvedMessage, 'dummy:profile.title');
      },
    );

    // -------------------------------------------------------------------------
    // 11. Message resolver: original-message fallback
    // -------------------------------------------------------------------------

    testWidgets('returns original message when no resolver is configured', (
      tester,
    ) async {
      String? resolvedMessage;

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
                resolvedMessage = context.resolveViewStateMessage(
                  'Original message',
                );

                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolvedMessage, 'Original message');
    });

    testWidgets(
      'returns original message when all configured resolvers return null',
      (tester) async {
        String? resolvedMessage;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateWidgetsProvider(
              initialStateBuilder: dummyInitialBuilder,
              loadingStateBuilder: dummyLoadingBuilder,
              emptyStateBuilder: dummyEmptyBuilder,
              errorStateBuilder: dummyErrorBuilder,
              messageResolver: unhandledMessageResolver,
              child: Builder(
                builder: (context) {
                  return ViewStateWidgetsProvider.override(
                    context: context,
                    messageResolver: unhandledMessageResolver,
                    child: Builder(
                      builder: (nestedContext) {
                        resolvedMessage = nestedContext.resolveViewStateMessage(
                          'Original message',
                        );

                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(resolvedMessage, 'Original message');
      },
    );

    // -------------------------------------------------------------------------
    // 12. Message resolver: empty-string handling
    // -------------------------------------------------------------------------

    testWidgets('treats an empty string as a successfully resolved message', (
      tester,
    ) async {
      String? resolvedMessage;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            messageResolver: emptyStringMessageResolver,
            child: Builder(
              builder: (context) {
                resolvedMessage = context.resolveViewStateMessage(
                  'profile.title',
                );

                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolvedMessage, '');
    });

    // -------------------------------------------------------------------------
    // 13. Message resolver: null input
    // -------------------------------------------------------------------------

    testWidgets('returns null without invoking resolver when message is null', (
      tester,
    ) async {
      var resolverCalled = false;
      String? resolvedMessage;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateWidgetsProvider(
            initialStateBuilder: dummyInitialBuilder,
            loadingStateBuilder: dummyLoadingBuilder,
            emptyStateBuilder: dummyEmptyBuilder,
            errorStateBuilder: dummyErrorBuilder,
            messageResolver: (context, message) {
              resolverCalled = true;
              return 'resolved:$message';
            },
            child: Builder(
              builder: (context) {
                resolvedMessage = context.resolveViewStateMessage(null);

                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolvedMessage, isNull);
      expect(resolverCalled, isFalse);
    });

    // -------------------------------------------------------------------------
    // 14. Message resolver: ancestor changes while override is mounted
    // -------------------------------------------------------------------------

    testWidgets('updates resolved message when ancestor resolver changes', (
      tester,
    ) async {
      late StateSetter updateHostState;
      var useCustomParentResolver = false;
      String? resolvedMessage;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHostState = setState;

              return ViewStateWidgetsProvider(
                initialStateBuilder: dummyInitialBuilder,
                loadingStateBuilder: dummyLoadingBuilder,
                emptyStateBuilder: dummyEmptyBuilder,
                errorStateBuilder: dummyErrorBuilder,
                messageResolver: useCustomParentResolver
                    ? customMessageResolver
                    : dummyMessageResolver,
                child: Builder(
                  builder: (scopeContext) {
                    return ViewStateWidgetsProvider.override(
                      context: scopeContext,
                      messageResolver: unhandledMessageResolver,
                      child: Builder(
                        builder: (nestedContext) {
                          resolvedMessage = nestedContext
                              .resolveViewStateMessage('profile.title');

                          return Text(resolvedMessage ?? '<null>');
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(resolvedMessage, 'dummy:profile.title');
      expect(find.text('dummy:profile.title'), findsOneWidget);

      updateHostState(() {
        useCustomParentResolver = true;
      });

      await tester.pump();

      expect(resolvedMessage, 'custom:profile.title');
      expect(find.text('custom:profile.title'), findsOneWidget);
      expect(find.text('dummy:profile.title'), findsNothing);
    });
  });
}
