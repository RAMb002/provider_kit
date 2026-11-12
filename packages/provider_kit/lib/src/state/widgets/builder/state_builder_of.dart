part of 'state_builder.dart';

/// Private implementation of [StateBuilder.of].
///
/// Resolves the [StateListenable] from the widget tree.
class _StateBuilderOf<P extends StateListenable<T>, T>
    extends _CallbackStateBuilderBase<P, T> {
  const _StateBuilderOf({
    super.key,
    required super.builder,
    super.selectListenable,
    super.rebuildWhen,
    super.child,
  }) : super(listenable: null);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<SelectStateListenable<P, T>>.has(
        'selectListenable',
        selectListenable,
      ),
    );
  }
}
