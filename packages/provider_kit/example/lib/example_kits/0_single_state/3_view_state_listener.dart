import 'package:example/example_kits/providers/2_future_notifier.dart';
import 'package:example/repository/repository.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class ViewStateListenerExample extends StatelessWidget {
  const ViewStateListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ItemsProvider(),
      builder: (context, child) {
        return ScaffoldWithButton(
            title: "View State Listener",
            icon: Icons.refresh,
            onTap: () => context.read<ItemsProvider>().refresh(),
            child: ViewStateListener.of<ItemsProvider, List<Item>>(
              callListenerOnInit: true,
              initialStateListener: (context) => context.showToast("initial state"),
              loadingStateListener: (context, details) =>
                  context.showToast("loading state"),
              emptyStateListener: (context, details) => context.showToast("empty state"),
              dataStateListener: (context,data) => context.showToast(data.toString()),
              errorStateListener:
                  (context, details) =>
                      context.showToast("error state, message - ${details.errorInfo.message}"),
              child: const Text("We are just listening"),
            ));
      },
    );
  }
}
