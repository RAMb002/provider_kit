import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';

/// {@template provider_kit.view_state_widget_provider}
/// Configures the default UI builders and message resolution for view states.
///
/// Wrap your application's `MaterialApp` with a [ViewStateWidgetsProvider] to configure
/// default widgets for initial, loading, error, and empty states. These
/// defaults are used by [ViewStateBuilder] and [ViewStateConsumer] whenever
/// a custom builder is not provided.
///
/// Use [messageResolver] to centralize localization of state messages.
/// Resolvers can use the current [BuildContext] to access your application's
/// localization system. Return `null` when a message cannot be resolved,
/// allowing parent providers to try. If no resolver handles the message,
/// the original message is used.
///
/// ### Example
///
/// ```dart
/// ViewStateWidgetsProvider(
///   initialStateBuilder: (_, _) => const SizedBox.shrink(),
///   loadingStateBuilder: (_, details, _) =>
///       Text(details.message ?? 'Loading...'),
///   emptyStateBuilder: (_, details, _) =>
///       Text(details.message ?? 'No results found.'),
///   errorStateBuilder: (_, details, _) =>
///       Text(details.message ?? 'Something went wrong.'),
///   messageResolver: (context, message) {
///     return switch (message) {
///       'profile.loading' => 'Loading profile...',
///       'profile.empty' => 'No profile found.',
///       _ => null,
///     };
///   },
///   child: const MyApp(),
/// )
/// ```
///
/// ### Override defaults for a subtree
///
/// Use [ViewStateWidgetsProvider.override] to customize selected builders
/// or message resolution for a screen or route. Any builders you omit
/// continue to use the parent provider's defaults. A local message resolver
/// can handle screen-specific messages and return `null` to let parent
/// resolvers handle other messages.
///
/// ```dart
/// ViewStateWidgetsProvider.override(
///   context: context,
///   loadingStateBuilder: (_, details, isSliver) =>
///       const Center(child: Text('Loading profile...')),
///   messageResolver: (_, message) {
///     if (message == 'profile.empty') return 'No profile found.';
///     return null;
///   },
///   child: const ProfileScreen(),
/// )
/// ```
///
/// Replace the example strings with values from your localization system.
/// Builders can use `isSliver` to return widgets appropriate for regular
/// or sliver layouts.
///
/// See also:
/// - [ViewStateBuilder], for building UI from a view state.
/// - [ViewStateConsumer], for building UI and listening to state changes.
/// - [ViewStateWidgetsProvider.override], for scoped customization.
/// {@endtemplate}
class ViewStateWidgetsProvider extends InheritedWidget {
  /// {@macro provider_kit.view_state_widget_provider}
  const ViewStateWidgetsProvider({
    required this.initialStateBuilder,
    required this.loadingStateBuilder,
    required this.errorStateBuilder,
    required this.emptyStateBuilder,
    this.messageResolver,
    required super.child,
    super.key,
  }) : _parentProvider = null;

  const ViewStateWidgetsProvider._({
    required this.initialStateBuilder,
    required this.loadingStateBuilder,
    required this.errorStateBuilder,
    required this.emptyStateBuilder,
    required this.messageResolver,
    required ViewStateWidgetsProvider parent,
    required super.child,
    super.key,
  }) : _parentProvider = parent;

  /// Creates a scoped [ViewStateWidgetsProvider] for a subtree
  /// (e.g., a specific route or screen).
  ///
  /// Any builder explicitly provided to this constructor will override the
  /// parent provider's builder for that subtree. Any builder omitted (`null`)
  /// will continue to use the parent provider's builder.
  ///
  /// A [messageResolver] is tried before the parent provider's resolver.
  /// If the local resolver returns `null`, resolution continues through the
  /// parent providers until a resolver returns a non-null result.
  ///
  /// If no resolver handles a message, the original message is used.
  factory ViewStateWidgetsProvider.override({
    required BuildContext context,
    required Widget child,
    DefaultInitialStateBuilder? initialStateBuilder,
    DefaultLoadingStateBuilder? loadingStateBuilder,
    DefaultErrorStateBuilder? errorStateBuilder,
    DefaultEmptyStateBuilder? emptyStateBuilder,
    ViewStateMessageResolver? messageResolver,
    Key? key,
  }) {
    final parent = ViewStateWidgetsProvider.of(context);

    return ViewStateWidgetsProvider._(
      key: key,
      initialStateBuilder: initialStateBuilder ?? parent.initialStateBuilder,
      loadingStateBuilder: loadingStateBuilder ?? parent.loadingStateBuilder,
      errorStateBuilder: errorStateBuilder ?? parent.errorStateBuilder,
      emptyStateBuilder: emptyStateBuilder ?? parent.emptyStateBuilder,
      messageResolver: messageResolver,
      parent: parent,
      child: child,
    );
  }

  /// Builds the default UI for an initial state.
  ///
  /// Receives the current context and `isSliver`.
  final DefaultInitialStateBuilder initialStateBuilder;

  /// Builds the default UI for a loading state.
  ///
  /// Receives the current context, loading details, and `isSliver`.
  final DefaultLoadingStateBuilder loadingStateBuilder;

  /// Builds the default UI for an error state.
  ///
  /// Receives the current context, error details, and `isSliver`.
  final DefaultErrorStateBuilder errorStateBuilder;

  /// Builds the default UI for an empty state.
  ///
  /// Receives the current context, empty-state details, and `isSliver`.
  final DefaultEmptyStateBuilder emptyStateBuilder;

  /// Resolves a state message using the current build context.
  ///
  /// This resolver is tried before the parent provider's resolver.
  /// Return `null` when the message cannot be resolved.
  ///
  /// If no resolver in the provider hierarchy handles the message, the
  /// original message is used as a fallback.
  final ViewStateMessageResolver? messageResolver;

  /// The parent provider used to continue message resolution.
  final ViewStateWidgetsProvider? _parentProvider;

  /// Resolves [message] using this provider and its parent providers.
  ///
  /// The nearest resolver that returns a non-null result takes precedence.
  /// Returns `null` when no resolver handles the message.
  String? _resolveMessage(BuildContext context, String message) {
    final resolved = messageResolver?.call(context, message);

    if (resolved != null) {
      return resolved;
    }

    return _parentProvider?._resolveMessage(context, message);
  }

  /// Whether the message resolver chain has changed.
  ///
  /// Returns `true` if this provider or any of its parent providers
  /// has a different message resolver.
  bool _shouldNotifyForMessageResolverChain(
    ViewStateWidgetsProvider oldWidget,
  ) {
    if (messageResolver != oldWidget.messageResolver) {
      return true;
    }

    final parent = _parentProvider;
    final oldParent = oldWidget._parentProvider;

    if (parent == null || oldParent == null) {
      return parent != oldParent;
    }

    return parent._shouldNotifyForMessageResolverChain(oldParent);
  }

  /// Retrieves the nearest [ViewStateWidgetsProvider] instance in the widget tree.
  static ViewStateWidgetsProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ViewStateWidgetsProvider>();
  }

  /// Retrieves the nearest [ViewStateWidgetsProvider] instance in the widget tree.
  ///
  /// Throws an assertion error if no [ViewStateWidgetsProvider] is found.
  static ViewStateWidgetsProvider of(BuildContext context) {
    final ViewStateWidgetsProvider? result = maybeOf(context);
    assert(result != null, 'No ViewStateWidgetsProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ViewStateWidgetsProvider oldWidget) =>
      oldWidget.initialStateBuilder != initialStateBuilder ||
      oldWidget.loadingStateBuilder != loadingStateBuilder ||
      oldWidget.errorStateBuilder != errorStateBuilder ||
      oldWidget.emptyStateBuilder != emptyStateBuilder ||
      _shouldNotifyForMessageResolverChain(oldWidget);
}

/// Extension on [BuildContext] to easily access the state widget builders
/// and message resolution from [ViewStateWidgetsProvider].
extension ViewStateWidgetsContextX on BuildContext {
  /// Retrieves the initial state widget builder from the nearest provider.
  DefaultInitialStateBuilder get initialStateWidget =>
      ViewStateWidgetsProvider.of(this).initialStateBuilder;

  /// Retrieves the loading state widget builder from the nearest provider.
  DefaultLoadingStateBuilder get loadingStateWidget =>
      ViewStateWidgetsProvider.of(this).loadingStateBuilder;

  /// Retrieves the error state widget builder from the nearest provider.
  DefaultErrorStateBuilder get errorStateWidget =>
      ViewStateWidgetsProvider.of(this).errorStateBuilder;

  /// Retrieves the empty state widget builder from the nearest provider.
  DefaultEmptyStateBuilder get emptyStateWidget =>
      ViewStateWidgetsProvider.of(this).emptyStateBuilder;

  /// Resolves a view-state message using the nearest provider.
  ///
  /// If no resolver handles the message, the original message is returned.
  /// Returns `null` when [message] is `null`.
  String? resolveViewStateMessage(String? message) {
    if (message == null) return null;

    final provider = ViewStateWidgetsProvider.maybeOf(this);

    return provider?._resolveMessage(this, message) ?? message;
  }
}

/// Resolves a state message using the current build context.
///
/// Return `null` when the message cannot be resolved, allowing the parent
/// provider's resolver to try. If no resolver handles the message, the
/// original message is used as a fallback.
typedef ViewStateMessageResolver =
    String? Function(BuildContext context, String message);
