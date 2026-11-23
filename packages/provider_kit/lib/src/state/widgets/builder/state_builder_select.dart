part of 'state_builder.dart';

class _StateBuilderSelect<P extends ChangeNotifier, T>
    extends _CallbackStateBuilderBase<P, T> {
  const _StateBuilderSelect({
    super.key,
    required super.selector,
    required super.builder,
    super.rebuildWhen,
    super.child,
  }) : super(listenable: null);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<SelectStateListenable<P, T>>.has('selector', selector),
    );
  }
}
