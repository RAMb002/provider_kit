import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/scaffold_with_multi_button.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiStateConsumerExample extends StatefulWidget {
  const MultiStateConsumerExample({super.key});

  @override
  State<MultiStateConsumerExample> createState() =>
      _MultiStateConsumerExampleState();
}

class _MultiStateConsumerExampleState extends State<MultiStateConsumerExample> {
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
      title: "Multi State Consumer",
      onTap1: () => provider1.increment(),
      onTap2: () => provider2.increment(),
      onTap3: () => provider3.increment(),
      child: MultiStateConsumer<int>(
        providers: [provider1, provider2, provider3],
        listener: (context, states) {
          context.showToast(states.toString());
        },
        builder: (context, states, child) => Text(states.toString()),
      ),
    );
  }
}
