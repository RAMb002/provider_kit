import 'package:example/example_Template.dart';
import 'package:example/example_kits/providers/2_provider_kit.dart';
import 'package:example/repository/repository.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class ViewStateConsumerExample extends StatelessWidget {
  const ViewStateConsumerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProviderKitProvider(),
      builder: (context, child) {
        return ExampleTemplate(
            title: "View State Observer",
            child: ViewStateConsumer<ProviderKitProvider, List<Item>>(
              initialStateListener: () => context.showToast('initial'),
              shouldcallListenerOnInit: true,
              dataStateListener: (data) => context.showToast(data.toString()),
              dataBuilder: (data) => Text(data.toString()),
            ));
      },
    );
  }
}
