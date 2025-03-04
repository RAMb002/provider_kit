import 'package:example/example_kits/providers/1_view_state_notifier.dart';
import 'package:example/example_kits/providers/2_provider_kit.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiViewStateBuilderExample extends StatelessWidget {
  const MultiViewStateBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = [
      ItemsProvider(),
      ViewStateProviderOne(),
      ViewStateProviderTwo()
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
        ));
  }
}
