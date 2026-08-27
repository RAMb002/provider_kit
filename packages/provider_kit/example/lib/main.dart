// ignore_for_file: unused_import
import 'package:example/example_kits/0_single_state/0_state_listener.dart';
import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/example_kits/0_single_state/2_state_consumer.dart';
import 'package:example/example_kits/0_single_state/3_view_state_listener.dart';
import 'package:example/example_kits/0_single_state/4_view_state_builder.dart';
import 'package:example/example_kits/0_single_state/5_view_state_consumer.dart';
import 'package:example/example_kits/1_multi_state/10_multi_view_state_builder.dart';
import 'package:example/example_kits/1_multi_state/11_multi_view_state_consumer.dart';
import 'package:example/example_kits/1_multi_state/6_multi_state_listener.dart';
import 'package:example/example_kits/1_multi_state/7_multi_state_builder.dart';
import 'package:example/example_kits/1_multi_state/8_multi_state_consumer.dart';
import 'package:example/example_kits/1_multi_state/9_multi_view_state_listener.dart';
import 'package:example/example_kits/mutations/mutation.dart';
import 'package:example/example_kits/mutations/mutation_group.dart';
import 'package:example/example_kits/observer/notifier_observer.dart';
import 'package:example/states_widget/empty_state_widget.dart';
import 'package:example/states_widget/error_state_widget.dart';
import 'package:example/states_widget/initial_state_widget.dart';
import 'package:example/states_widget/loading_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  ProviderKit.configure(observer: NotifierLogger());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewStateWidgetsProvider(
      initialStateBuilder: (isSliver) => InitialStateWidget(
        isSliver: isSliver,
      ),
      emptyStateBuilder: (message, isSliver) =>
          EmptyStateWidget(isSliver: isSliver),
      errorStateBuilder: (error, onRetry, exception, stackTrace, isSliver) =>
          ErrorStateWidget(
              text: error ?? "something went wrong",
              onTap: onRetry,
              isSliver: isSliver),
      loadingStateBuilder: (message, progress, isSliver) =>
          LoadingStateWidget(isSliver: isSliver),
      child: MaterialApp(
        title: 'Provider Kit Widgets Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ExamplePickerScreen(),
      ),
    );
  }
}

class ExampleItem {
  final String title;
  final String category;
  final Widget widget;

  const ExampleItem({
    required this.title,
    required this.category,
    required this.widget,
  });
}

class ExamplePickerScreen extends StatelessWidget {
  const ExamplePickerScreen({super.key});

  // Map out all your examples in one clean list
  static final List<ExampleItem> examples = [
    // --- Single State ---
    const ExampleItem(
      title: '0. State Listener',
      category: 'Single State',
      widget: StateListenerExample(),
    ),
    const ExampleItem(
      title: '1. State Builder',
      category: 'Single State',
      widget: StateBuilderExample(),
    ),
    const ExampleItem(
      title: '2. State Consumer',
      category: 'Single State',
      widget: StateConsumerExample(),
    ),
    const ExampleItem(
      title: '3. View State Listener',
      category: 'Single State',
      widget: ViewStateListenerExample(),
    ),
    const ExampleItem(
      title: '4. View State Builder',
      category: 'Single State',
      widget: ViewStateBuilderExample(),
    ),
    const ExampleItem(
      title: '5. View State Consumer',
      category: 'Single State',
      widget: ViewStateConsumerExample(),
    ),

    // --- Multi State ---
    const ExampleItem(
      title: '6. Multi State Listener',
      category: 'Multi State',
      widget: MultiStateListenerExample(),
    ),
    const ExampleItem(
      title: '7. Multi State Builder',
      category: 'Multi State',
      widget: MultiStateBuilderExample(),
    ),
    const ExampleItem(
      title: '8. Multi State Consumer',
      category: 'Multi State',
      widget: MultiStateConsumerExample(),
    ),
    const ExampleItem(
      title: '9. Multi View State Listener',
      category: 'Multi State',
      widget: MultiViewStateListenerExample(),
    ),
    const ExampleItem(
      title: '10. Multi View State Builder',
      category: 'Multi State',
      widget: MultiViewStateBuilderExample(),
    ),
    const ExampleItem(
      title: '11. Multi View State Consumer',
      category: 'Multi State',
      widget: MultiViewStateConsumerExample(),
    ),

    const ExampleItem(
      title: 'Mutation',
      category: '',
      widget: MutationExample(),
    ),

    const ExampleItem(
      title: 'Mutation Group',
      category: '',
      widget: MutationGroupExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Kit Demos'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: examples.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            title: Text(
              example.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: example.category.isEmpty ? null : Text(example.category),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => example.widget,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
