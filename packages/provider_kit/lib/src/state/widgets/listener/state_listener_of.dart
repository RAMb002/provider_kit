part of 'state_listener.dart';

class _StateListenerOf<P extends StateListenable<T>, T>
    extends _CallbackStateListenerBase<P, T> {
  const _StateListenerOf({
    super.key,
    required super.listener,
    super.selectListenable,
    super.listenWhen,
    super.callListenerOnInit,
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
