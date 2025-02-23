import 'package:example/example_Template.dart';
import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/toast.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class StateConsumerExample extends StatefulWidget {
  const StateConsumerExample({super.key});

  @override
  State<StateConsumerExample> createState() => _StateConsumerExampleState();
}

class _StateConsumerExampleState extends State<StateConsumerExample> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExampleProvider(1),
      builder: (context, child) {
        return ExampleTemplate(
            title: "State Observer",
            onTap: () {
              context.read<ExampleProvider>().increment();
              Future.delayed(const Duration(seconds: 1)).then((_) {
                setState(() {});
              });
            },
            child: StateConsumer<ExampleProvider, int>(
              listener: (context, state) {
                context.showToast(state.toString());
              },
              builder: (context, value, child) {
                return Text("$value");
              },
            ));
      },
    );
  }
}


