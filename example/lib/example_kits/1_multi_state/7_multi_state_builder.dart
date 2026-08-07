import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/scaffold_with_multi_button.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiStateBuilderExample extends StatefulWidget {
  const MultiStateBuilderExample({super.key});

  @override
  State<MultiStateBuilderExample> createState() =>
      _MultiStateBuilderExampleState();
}

class _MultiStateBuilderExampleState extends State<MultiStateBuilderExample> {
  late ExampleProvider provider1;
  late ExampleProvider provider2;
  late ExampleProvider provider3;

  @override
  void initState() {
    super.initState();
    provider1 = ExampleProvider(1);
    provider2 = ExampleProvider(100);
    provider3 = ExampleProvider(200);
  }

  @override
  void dispose() {
    provider1.dispose();
    provider2.dispose();
    provider3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithMultiButton(
      title: "Multi State Builder",
      onTap1: () => provider1.increment(),
      onTap2: () => provider2.increment(),
      onTap3: () => provider3.increment(),
      child: MultiStateBuilder<int>(
        providers: [provider1, provider2, provider3],
        builder: (context, states, child) => Text(states.toString()),
      ),
    );
  }
}
