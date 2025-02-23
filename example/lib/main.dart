// ignore_for_file: unused_import
import 'package:example/example_kits/1_multi_state/10_multi_view_state_builder.dart';
import 'package:example/example_kits/1_multi_state/11_multi_view_state_consumer.dart';
import 'package:example/example_kits/1_multi_state/6_multi_state_listener.dart';
import 'package:example/example_kits/1_multi_state/7_multi_state_builder.dart';
import 'package:example/example_kits/1_multi_state/8_multi_state_consumer.dart';
import 'package:example/example_kits/1_multi_state/9_multi_view_state_listener.dart';
import 'package:example/example_kits/0_single_state/0_state_listener.dart';
import 'package:example/example_kits/0_single_state/1_state_builder.dart';
import 'package:example/example_kits/0_single_state/2_state_consumer.dart';
import 'package:example/example_kits/0_single_state/3_view_state_listener.dart';
import 'package:example/example_kits/0_single_state/4_view_state_builder.dart';
import 'package:example/example_kits/0_single_state/5_view_state_consumer.dart';
import 'package:example/example_kits/observer/state_observer.dart';
import 'package:example/states_widget/empty_state_widget.dart';
import 'package:example/states_widget/error_state_widget.dart';
import 'package:example/states_widget/initial_state_widget.dart';
import 'package:example/states_widget/loading_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  StateNotifier.observer = NotifierLogger();
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
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),

        // home: const StateListenerExample(),
        //  home: const StateBuilderExample(),
        // home: const StateConsumerExample(),
        // home: const ViewStateListenerExample(),
        // home: const ViewStateBuilderExample(),
        // home: const ViewStateConsumerExample(),
        // home: const MultiStateListenerExample(),
        // home: const MultiStateBuilderExample(),
        // home: const MultiStateConsumerExample(),
        // home: const MultiViewStateListenerExample(),
        home: const MultiViewStateBuilderExample(),
        // home: const MultiViewStateConsumerExample(),
      ),
    );
  }
}

