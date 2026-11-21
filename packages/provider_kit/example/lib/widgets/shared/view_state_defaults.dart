import 'package:example/widgets/shared/view_state_widgets/empty_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/error_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/initial_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/loading_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Provides the default UI for ProviderKit View States
/// throughout the example application.
class ExampleViewStateDefaults extends StatelessWidget {
  const ExampleViewStateDefaults({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ViewStateWidgetsProvider(
      initialStateBuilder: (context, isSliver) => InitialStateWidget(
        isSliver: isSliver,
      ),
      loadingStateBuilder: (context, details, isSliver) => LoadingStateWidget(
        isSliver: isSliver,
        message: details.message,
      ),
      emptyStateBuilder: (context, details, isSliver) => EmptyStateWidget(
          message: details.message,
          onTap: details.onRefresh,
          isSliver: isSliver),
      errorStateBuilder: (context, details, isSliver) => ErrorStateWidget(
        message: details.message,
        onTap: details.onRetry,
        isSliver: isSliver,
      ),
      child: child,
    );
  }

  Widget _adaptForSliver(Widget child, bool isSliver) {
    return isSliver ? SliverToBoxAdapter(child: child) : child;
  }
}
