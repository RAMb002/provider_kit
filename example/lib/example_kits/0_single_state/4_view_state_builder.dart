import 'package:example/example_Template.dart';
import 'package:example/example_kits/providers/2_provider_kit.dart';
import 'package:example/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class ViewStateBuilderExample extends StatelessWidget {
  const ViewStateBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProviderKitProvider(),
      builder: (context, child) {
        return ExampleTemplate(
            title: "Provider View State Builder",
            child: ViewStateBuilder<ProviderKitProvider, List<Item>>(
              dataBuilder: (data) => Text(data.toString()),
            ));
      },
    );
  }
}
