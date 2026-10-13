part of 'view_state_builder.dart';

/// Private implementation of [ViewStateBuilder].
///
/// Configures a builder for a directly provided [ViewStateNotifier].
class _ViewStateBuilder<T>
    extends ViewStateBuilderBase<ViewStateNotifier<T>, T> {
  const _ViewStateBuilder({
    super.key,
    required ViewStateNotifier<T> provider,
    super.rebuildWhen,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.isSliver,
  }) : super(provider: provider);
}
