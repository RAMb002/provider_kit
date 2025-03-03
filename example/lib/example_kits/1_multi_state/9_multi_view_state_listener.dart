import 'package:example/example_kits/providers/1_view_state_notifier.dart';
import 'package:example/example_kits/providers/2_provider_kit.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiViewStateListenerExample extends StatelessWidget {
  const MultiViewStateListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [
      ItemsProvider(),
      ViewStateProviderOne(),
      ViewStateProviderTwo(),
    ];
    return ScaffoldWithButton(
      title: "Multi View State Listener",
      child: MultiViewStateListener(
        providers: providers,
        initialStateListener: () => context.showToast("initial state"),
        loadingStateListener: (message, progress) =>
            context.showToast("loading state"),
        emptyStateListener: (message) => context.showToast("empty state"),
        dataStateListener: (data) => context.showToast(data.toString()),
        errorStateListener: (errorMessage, onRetry, exception, stackTrace) =>
            context.showToast("error state, message - $errorMessage"),
        child: const Text("listening"),
      ),
    );
  }
}
