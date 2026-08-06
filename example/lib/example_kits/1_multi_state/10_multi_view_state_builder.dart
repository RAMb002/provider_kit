import 'package:example/example_kits/providers/1_view_state_notifier.dart';
import 'package:example/example_kits/providers/2_async_view_state_notifier.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiViewStateBuilderExample extends StatelessWidget {
  const MultiViewStateBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => ViewStateProviderOne()),
        ChangeNotifierProvider(create: (_) => ViewStateProviderTwo()),
      ],
      child: Builder(
        builder: (context) {
          final providers = [
            context.read<ItemsProvider>(),
            context.read<ViewStateProviderOne>(),
            context.read<ViewStateProviderTwo>(),
          ];
          return ScaffoldWithButton(
            title: "Multi View State Builder",
            child: MultiViewStateBuilder(
              providers: providers,
              loadingBuilder: (message, progress, isSliver) {
                return const CircularProgressIndicator();
              },
              dataBuilder: (data) {
                return Text(data.toString());
              },
            ),
          );
        },
      ),
    );
  }
}