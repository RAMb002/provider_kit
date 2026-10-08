part of 'state_builder.dart';

/// Private implementation of [StateBuilder].
///
/// Configures a builder for a directly provided [StateValueListenable].
class _StateBuilder<T> extends StateBuilderBase<StateValueListenable<T>, T> {
  const _StateBuilder({
    super.key,
    required StateValueListenable<T> provider,
    required this.builder,
    super.rebuildWhen,
    super.child,
  }) : super(provider: provider);

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
