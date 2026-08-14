import 'package:example/scaffold_with_button.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class StateBuilderExample extends StatelessWidget {
  const StateBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExampleProvider(1),
      builder: (context, child) {
        final provider =
            context.watch<ExampleProvider>(); // or context.read, bu
        return ScaffoldWithButton(
            title: "State Builder",
            onTap: () => provider.increment(),
            child: StateBuilder<int>(
              provider: provider,
              builder: (context, state, child) {
                return Text(state.toString());
              },
            ));
      },
    );
  }
}

class ExampleProvider extends StateNotifier<int> {
  ExampleProvider(super.state);

  void increment() {
    state += 1;
  }
}
