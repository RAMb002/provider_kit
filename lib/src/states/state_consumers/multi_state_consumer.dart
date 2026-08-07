import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/states/state_builders/multi_state_builder.dart';
import 'package:provider_kit/src/utils/equality_check.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template providerkit-multistateconsumer}

/// A widget that combines both listening to and building based on the states of multiple [StateValueListenable]s.
///
/// The [MultiStateConsumer] widget is used to perform actions and build its child widget
/// in response to state changes in multiple [StateValueListenable]s. It ensures that the appropriate
/// listener and builder are called based on the current states.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [StateValueListenable]s that supply the states.
/// - **`builder`** (*Required*) **:** A function that constructs the widget tree based on the current states.
/// - **`listener`** (*Required*) **:** A callback function that is invoked when the states change.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current states. Defaults to calling the builder when `previous != current`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current states. Defaults to calling the listener when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`child`** (*Optional*) **:** A widget that is part of the widget tree.
///
/// ### Example Usage:
/// ```dart
/// MultiStateConsumer<State>(
///   providers: [provider1, provider2], // Required
///   builder: (context, states, child) {
///     final state1 = states[0];
///     final state2 = states[1];
///     // Build your widget tree based on the states
///     return Container();
///   },
///   listener: (context, states) {
///     final state1 = states[0];
///     final state2 = states[1];
///     // Perform actions based on the states
///   },
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   shouldCallListenerOnInit: true, // Optional, default is false
///   child: SomeWidget(), // Optional
/// )
/// ```
/// {@endtemplate}

class MultiStateConsumer<T> extends StatefulWidget {
  /// {@macro providerkit-multistateconsumer}
  const MultiStateConsumer({
    super.key,
    required this.builder,
    this.rebuildWhen,
    required this.listener,
    this.listenWhen,
    required this.providers,
    this.shouldCallListenerOnInit = false,
    this.child,
  });

  final List<StateValueListenable<T>> providers;
  final MultiStateWidgetBuilder<List<T>> builder;
  final RebuildWhen<List<T>>? rebuildWhen;
  final ListenWhen<List<T>>? listenWhen;
  final MultiListenerCallback<List<T>> listener;
  final Widget? child;
  final bool shouldCallListenerOnInit;

  @override
  State<MultiStateConsumer<T>> createState() => _MultiStateConsumerState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<List<StateValueListenable<T>>?>(
          'providers', providers))
      ..add(ObjectFlagProperty<MultiStateWidgetBuilder<List<T>>>.has(
          'builder', builder))
      ..add(ObjectFlagProperty<MultiListenerCallback<List<T>>>.has(
          'listener', listener))
      ..add(
        ObjectFlagProperty<RebuildWhen<List<T>>?>.has(
          'rebuildWhen',
          rebuildWhen,
        ),
      )
      ..add(
        ObjectFlagProperty<ListenWhen<List<T>>?>.has(
          'listenWhen',
          listenWhen,
        ),
      )
      ..add(DiagnosticsProperty<bool>(
        'shouldCallListenerOnInit',
        shouldCallListenerOnInit,
        defaultValue: false,
      ))
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }
}

class _MultiStateConsumerState<T> extends State<MultiStateConsumer<T>> {
  late List<StateValueListenable<T>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = List<StateValueListenable<T>>.from(widget.providers);
    if (widget.shouldCallListenerOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.listener(
          context,
          List<T>.unmodifiable(_providers.map((notifier) => notifier.state)),
        );
      });
    }
  }

  @override
  void didUpdateWidget(MultiStateConsumer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_areProviderListsEqual(_providers, widget.providers)) {
      _update();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_areProviderListsEqual(_providers, widget.providers)) {
      _update();
    }
  }

  void _update() {
    _providers = List<StateValueListenable<T>>.from(widget.providers);
  }

  bool _areProviderListsEqual(
      List<StateValueListenable<T>> a, List<StateValueListenable<T>> b) {
    return ObjectKit.areProviderListsEqual(a, b);
  }

  @override
  Widget build(BuildContext context) {
    return MultiStateBuilder<T>(
      providers: _providers,
      builder: widget.builder,
      child: widget.child,
      rebuildWhen: (previous, next) {
        if ((ObjectKit.isNotEqual<List<T>>(
            widget.listenWhen, previous, next))) {
          widget.listener(context, next);
        }
        return (ObjectKit.isNotEqual<List<T>>(
            widget.rebuildWhen, previous, next));
      },
    );
  }
}
