import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';

/// Resolves a state message using the current build context.
///
/// Return `null` when the message cannot be resolved, allowing the parent
/// provider's resolver to try. If no resolver handles the message, the
/// original message is used as a fallback.
typedef ViewStateMessageResolver =
    String? Function(BuildContext context, String message);

/// Used to configure default widgets for InitialState, LoadingState, ErrorState, and EmptyState.
///
/// Wrap this widget around any widget to change the default widgets for these
/// states within its widget sub-tree.
///
/// Make sure to wrap this widget around the [MaterialApp], so that all pages
/// and widgets can have access to these default state widgets.
class ViewStateWidgetsProvider extends InheritedWidget {
  /// Creates a root [ViewStateWidgetsProvider] with all required state builders.
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
    InitialStateBuilder? initialStateBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
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

  /// Builder function for the initial state widget.
  final InitialStateBuilder initialStateBuilder;

  /// Builder function for the loading state widget.
  final LoadingStateBuilder loadingStateBuilder;

  /// Builder function for the error state widget.
  final ErrorStateBuilder errorStateBuilder;

  /// Builder function for the empty state widget.
  final EmptyStateBuilder emptyStateBuilder;

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
extension ContextX on BuildContext {
  /// Retrieves the initial state widget builder from the nearest provider.
  InitialStateBuilder get initialStateWidget =>
      ViewStateWidgetsProvider.of(this).initialStateBuilder;

  /// Retrieves the loading state widget builder from the nearest provider.
  LoadingStateBuilder get loadingStateWidget =>
      ViewStateWidgetsProvider.of(this).loadingStateBuilder;

  /// Retrieves the error state widget builder from the nearest provider.
  ErrorStateBuilder get errorStateWidget =>
      ViewStateWidgetsProvider.of(this).errorStateBuilder;

  /// Retrieves the empty state widget builder from the nearest provider.
  EmptyStateBuilder get emptyStateWidget =>
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
