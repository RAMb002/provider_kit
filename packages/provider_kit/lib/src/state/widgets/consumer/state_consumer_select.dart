part of 'state_consumer.dart';

class _StateConsumerSelect<P extends ChangeNotifier, T>
    extends _CallbackStateConsumerBase<P, T> {
  const _StateConsumerSelect({
    super.key,
    required super.selector,
    required super.builder,
    required super.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
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
