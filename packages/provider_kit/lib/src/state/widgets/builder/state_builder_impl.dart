part of 'state_builder.dart';

/// Private implementation of [StateBuilder].
///
/// Configures a builder for a directly provided [StateValueListenable].
class _StateBuilder<T>
    extends _CallbackStateBuilderBase<StateValueListenable<T>, T> {
  const _StateBuilder({
    super.key,
    required StateValueListenable<T> provider,
    required super.builder,
    super.rebuildWhen,
    super.child,
  }) : super(provider: provider);
}

/// Shared implementation for callback-based [StateBuilder] variants.
abstract class _CallbackStateBuilderBase<P extends StateValueListenable<T>, T>
    extends StateBuilderBase<P, T> {
  const _CallbackStateBuilderBase({
    super.key,
    required this.builder,
    super.provider,
    super.rebuildWhen,
    super.child,
  });

  /// {@template provider_kit.state_builder.builder}
  /// Builds the widget tree whenever the state changes and
  /// [rebuildWhen] allows the rebuild.
  ///
  /// The [child] is an optional widget that is not rebuilt when the state
  /// changes.
  /// {@endtemplate}
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
