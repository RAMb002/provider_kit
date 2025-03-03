import 'package:flutter/widgets.dart';
import 'utils/type_definitions.dart';

/// Used to configure default widgets for InitialState, LoadingState, ErrorState, and EmptyState.
/// Wrap this widget around any widget to change the default widgets for these states within its widget sub-tree.
///
/// Make sure to wrap this widget around the [MaterialApp], so that all pages and widgets can have access to these default state widgets.
class ViewStateWidgetsProvider extends InheritedWidget {
  const ViewStateWidgetsProvider({
    required this.initialStateBuilder,
    required this.loadingStateBuilder,
    required this.errorStateBuilder,
    required this.emptyStateBuilder,
    required super.child,
    super.key,
  });

  /// Builder function for the initial state widget.
  final InitialStateBuilder initialStateBuilder;

  /// Builder function for the loading state widget.
  final LoadingStateBuilder loadingStateBuilder;

  /// Builder function for the error state widget.
  final ErrorStateBuilder errorStateBuilder;

  /// Builder function for the empty state widget.
  final EmptyStateBuilder emptyStateBuilder;

  /// Retrieves the nearest [ViewStateWidgetsProvider] instance in the widget tree.
  static ViewStateWidgetsProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ViewStateWidgetsProvider>();
  }

  /// Retrieves the nearest [ViewStateWidgetsProvider] instance in the widget tree.
  /// Throws an assertion error if no [ViewStateWidgetsProvider] is found.
  static ViewStateWidgetsProvider of(BuildContext context) {
    final ViewStateWidgetsProvider? result = maybeOf(context);
    assert(result != null, 'No ViewStateWidgetsProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ViewStateWidgetsProvider oldWidget) =>
      oldWidget.initialStateBuilder != initialStateBuilder &&
      oldWidget.loadingStateBuilder != loadingStateBuilder &&
      oldWidget.errorStateBuilder != errorStateBuilder &&
      oldWidget.emptyStateBuilder != emptyStateBuilder;
}

/// Extension on [BuildContext] to easily access the state widget builders from [ViewStateWidgetsProvider].
extension ContextX on BuildContext {
  /// Retrieves the initial state widget builder from the nearest [ViewStateWidgetsProvider].
  InitialStateBuilder get initialStateWidget =>
      ViewStateWidgetsProvider.of(this).initialStateBuilder;

  /// Retrieves the loading state widget builder from the nearest [ViewStateWidgetsProvider].
  LoadingStateBuilder get loadingStateWidget =>
      ViewStateWidgetsProvider.of(this).loadingStateBuilder;

  /// Retrieves the error state widget builder from the nearest [ViewStateWidgetsProvider].
  ErrorStateBuilder get errorStateWidget =>
      ViewStateWidgetsProvider.of(this).errorStateBuilder;

  /// Retrieves the empty state widget builder from the nearest [ViewStateWidgetsProvider].
  EmptyStateBuilder get emptyStateWidget =>
      ViewStateWidgetsProvider.of(this).emptyStateBuilder;
}
