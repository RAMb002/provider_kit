part of 'state_builder.dart';

/// Private implementation of [StateBuilder.of].
///
/// Resolves the [StateValueListenable] from the widget tree.
class _StateBuilderOf<P extends StateValueListenable<T>, T>
    extends StateBuilderBase<P, T> {
  const _StateBuilderOf({
    super.key,
    required this.builder,
    super.rebuildWhen,
    super.child,
  }) : super(provider: null);

  final StateWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state, Widget? child) {
    return builder(context, state, child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<StateWidgetBuilder<T>>.has('builder', builder),
    );
  }
}