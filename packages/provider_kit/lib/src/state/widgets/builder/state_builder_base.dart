part of 'state_builder.dart';

/// Base class for [StateBuilder] implementations.
///
/// Provides the shared listenable, rebuild predicate, and child configuration
/// used by state-based builder widgets.
abstract class StateBuilderBase<P, T> extends StateBuilder<T> {
  const StateBuilderBase({
    super.key,
    this.listenable,
    this.selector,
    super.rebuildWhen,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.state_listener.listenable}
  final StateListenable<T>? listenable;

  /// {@macro provider_kit.state_listener.selector}
  final SelectStateListenable<P, T>? selector;

  /// The function that builds the widget tree based on the current state.
  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<StateBuilderBase<P, T>> createState() => _StateBuilderBaseState<P, T>();
}

/// The state class for [StateBuilderBase].
class _StateBuilderBaseState<P, T> extends State<StateBuilderBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    return StateEngine<P, T>(
      listenable: widget.listenable,
      selector: widget.selector,
      rebuildWhen: widget.rebuildWhen,
      builder: widget.build,
      widgetName: widget.debugWidgetName,
      child: widget.child,
    );
  }
}
