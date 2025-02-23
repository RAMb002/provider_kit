import 'package:example/example_Template.dart';
import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/toast.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class StateListenerExample extends StatelessWidget {
  const StateListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExampleProvider(1),
      builder: (context, child) {
        return ExampleTemplate(
            title: "State listener",
            onTap: () => context.read<ExampleProvider>().increment(),
            child: StateListener(
              provider: context.read<ExampleProvider>(),
              listener: (context, state) {
                context.showToast(state.toString());
              },
              child: const Text("This is just a text"),
            ));
      },
    );
  }
}
