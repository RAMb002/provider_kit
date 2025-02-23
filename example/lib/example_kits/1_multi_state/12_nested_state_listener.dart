import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/example_template.dart';
import 'package:example/toast.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/provider_kit.dart';

class ProviderMutliStateListenerExample extends StatelessWidget {
  const ProviderMutliStateListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExampleTemplate(
      onTap: () {},
      title: 'provider multi state listener',
      child: NestedStateListener(
        listeneres: [
          StateListener<ExampleProvider, int>(
              provider: ExampleProvider(1),
              listener: (context, state) {
                context.showToast(state.toString());
              }),
          StateListener<ExampleProvider, int>(
              provider: ExampleProvider(2),
              listener: (context, state) {
                context.showToast(state.toString());
              }),
          StateListener<ExampleProvider, int>(
              provider: ExampleProvider(3),
              listener: (context, state) {
                context.showToast(state.toString());
              }),
        ],
        child: const Text('data'),
      ),
    );
  }
}
