import 'package:flutter/widgets.dart';

import 'utils/type_definitions.dart';

/// Used to configure default widget for InitialState, LoadingState and FailedState.
/// Wrap over any widget to change the default widgets for these states for its widget sub-tree.
///
/// Make sure to wrap this widget over the [MaterialApp], so that all pages and widgets can have access to this.
class ViewStateWidgetsProvider extends InheritedWidget {
  const ViewStateWidgetsProvider({
    required this.initialStateBuilder,
    required this.loadingStateBuilder,
    required this.errorStateBuilder,
    required this.emptyStateBuilder,
    required super.child,
    super.key,
  });

  final InitialStateBuilder initialStateBuilder;
  final LoadingStateBuilder loadingStateBuilder;
  final ErrorStateBuilder errorStateBuilder;
  final EmptyStateBuilder emptyStateBuilder;

  static ViewStateWidgetsProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ViewStateWidgetsProvider>();
  }

  static ViewStateWidgetsProvider of(BuildContext context) {
    final ViewStateWidgetsProvider? result = maybeOf(context);
    assert(result != null, 'No StateWidgetsProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ViewStateWidgetsProvider oldWidget) =>
      oldWidget.initialStateBuilder != initialStateBuilder &&
      oldWidget.loadingStateBuilder != loadingStateBuilder &&
      oldWidget.errorStateBuilder != errorStateBuilder &&
      oldWidget.emptyStateBuilder != emptyStateBuilder;
}

extension ContextX on BuildContext {
  InitialStateBuilder get initialStateWidget =>
      ViewStateWidgetsProvider.of(this).initialStateBuilder;
  LoadingStateBuilder get loadingStateWidget =>
      ViewStateWidgetsProvider.of(this).loadingStateBuilder;
  ErrorStateBuilder get errorStateWidget =>
      ViewStateWidgetsProvider.of(this).errorStateBuilder;
  EmptyStateBuilder get emptyStateWidget =>
      ViewStateWidgetsProvider.of(this).emptyStateBuilder;
}
