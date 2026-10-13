part of 'view_state_builder.dart';

/// Private implementation of [ViewStateBuilder.of].
///
/// Resolves the [ViewStateNotifier] from the widget tree.
class _ViewStateBuilderOf<P extends ViewStateNotifier<T>, T>
    extends ViewStateBuilderBase<P, T> {
  const _ViewStateBuilderOf({
    super.key,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.rebuildWhen,
    super.isSliver,
  }) : super(provider: null);
}