import 'package:example/example_Template.dart';
import 'package:example/example_kits/providers/2_provider_kit.dart';
import 'package:example/repository/repository.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class ViewStateListenerExample extends StatelessWidget {
  const ViewStateListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProviderKitProvider(),
      builder: (context, child) {
        return ExampleTemplate(
            title: "View State Listener",
            icon: Icons.refresh,
            onTap: () => context.read<ProviderKitProvider>().refresh(),
            child: ViewStateListener<ProviderKitProvider, List<Item>>(
              shouldcallListenerOnInit: true,
              initialStateListener: () => context.showToast("initial state"),
              loadingStateListener: (message, progress) =>
                  context.showToast("loading state"),
              emptyStateListener: (message) => context.showToast("empty state"),
              dataStateListener: (data) => context.showToast(data.toString()),
              errorStateListener:
                  (errorMessage, onRetry, exception, stackTrace) =>
                      context.showToast("error state, message - $errorMessage"),
              child: const Text("We are just listening"),
            ));
      },
    );
  }
}


