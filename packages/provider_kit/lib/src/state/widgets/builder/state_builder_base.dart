part of 'state_builder.dart';

/// Base class for [StateBuilder] implementations.
///
/// Provides the shared listenable, rebuild predicate, and child configuration
/// used by state-based builder widgets.
abstract class StateBuilderBase<P extends StateListenable<T>, T>
    extends StateBuilder<T> {
  const StateBuilderBase({
    super.key,
    this.listenable,
    super.rebuildWhen,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.state_listener.listenable}
  final P? listenable;

  /// The function that builds the widget tree based on the current state.
  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<StateBuilderBase<P, T>> createState() => _StateBuilderBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<P?>('listenable', listenable));
  }
}

/// The state class for [StateBuilderBase].
class _StateBuilderBaseState<P extends StateListenable<T>, T>
    extends State<StateBuilderBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    return StateEngine<P, T>(
      listenable: widget.listenable,
      rebuildWhen: widget.rebuildWhen,
      builder: widget.build,
      widgetName: widget.debugWidgetName,
      child: widget.child,
    );
  }
}
