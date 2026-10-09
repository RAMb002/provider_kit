part of 'state_builder.dart';

/// Private implementation of [StateBuilder.of].
///
/// Resolves the [StateValueListenable] from the widget tree.
class _StateBuilderOf<P extends StateValueListenable<T>, T>
    extends _CallbackStateBuilderBase<P, T> {
  const _StateBuilderOf({
    super.key,
    required super.builder,
    super.rebuildWhen,
    super.child,
  }) : super(provider: null);
}
