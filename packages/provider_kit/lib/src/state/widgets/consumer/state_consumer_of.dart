part of 'state_consumer.dart';

/// Private implementation of [StateConsumer.of].
///
/// Resolves the [StateListenable] from the widget tree.
class _StateConsumerOf<P extends StateListenable<T>, T>
    extends _CallbackStateConsumerBase<P, T> {
  const _StateConsumerOf({
    super.key,
    required super.builder,
    required super.listener,
    super.selectListenable,
    super.rebuildWhen,
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
