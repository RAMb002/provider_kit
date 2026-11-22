part of 'state_listener.dart';

class _StateListenerSelect<P extends ChangeNotifier, T>
    extends _CallbackStateListenerBase<P, T> {
  const _StateListenerSelect({
    super.key,
    required super.listener,
    required super.selector,
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
