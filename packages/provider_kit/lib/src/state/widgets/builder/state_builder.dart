import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/internal/rebuild_scheduler.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiStateBase;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/listener/state_listener.dart';

part 'multi_state_builder.dart';
part 'state_builder_base.dart';
part 'state_builder_impl.dart';
part 'state_builder_of.dart';

/// {@template provider_kit.state_builder}
/// A widget that rebuilds its UI when its state changes.
///
/// - Use [StateBuilder] to read state from a single provider.
/// - Use [StateBuilder.of] to read a provider from the widget tree.
/// - Use [StateBuilder.multi] to read and combine state from multiple providers.
///
/// The builder is called when the state changes and [rebuildWhen] allows the
/// rebuild. The optional [child] is preserved across rebuilds and can be used
/// for a subtree that does not depend on the state.
///
/// ### Example Usage:
/// ```dart
/// StateBuilder(
///   provider: provider,
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return Container();
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// )
/// ```
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [StateBuilder.of] to resolve it from the widget tree:
///
/// ```dart
/// StateBuilder.of<MyProvider, MyState>(
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return Container();
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// )
/// ```
/// This ensures optimal performance by rebuilding only when necessary and
/// preserving static UI elements passed as `child`.
/// {@endtemplate}
///
/// {@macro provider_kit.state_builder.multi}

abstract class StateBuilder<T> extends StatefulWidget {
  const StateBuilder.base({super.key, this.rebuildWhen, this.child});

  /// {@template provider_kit.state_builder.rebuild_when}
  /// Determines whether the builder should be called when the state changes.
  /// The callback receives the previous and current states.
  ///
  /// For [StateBuilder.multi], the states are the combined values returned
  /// by the `providers` callback.
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final RebuildWhen<T>? rebuildWhen;

  /// {@template provider_kit.state_builder.child}
  /// An optional widget that is passed to [builder] and is not rebuilt when the
  /// state changes.
  /// {@endtemplate}
  final Widget? child;

  /// {@macro provider_kit.state_builder}
  /// {@macro provider_kit.state_builder.multi}
  const factory StateBuilder({
    Key? key,
    required StateValueListenable<T> provider,
    required StateWidgetBuilder<T> builder,
    RebuildWhen<T>? rebuildWhen,
    Widget? child,
  }) = _StateBuilder<T>;

  /// {@template provider_kit.state_builder.multi}
  /// ### Listening to Multiple Providers
  ///
  /// Use [StateBuilder.multi] when a builder depends on the state of multiple
  /// providers. The [providers] callback builds a single combined state by
  /// reading provider values through `.watch`. ProviderKit automatically tracks
  /// every watched provider and re-evaluates the combined state whenever any of
  /// those providers change.
  ///
  /// The combined state returned by [providers] is passed to [builder] and
  /// [rebuildWhen]. It can be any Dart type, including a record, list, or custom
  /// object.
  ///
  /// A record can be used when you want named values:
  ///
  /// ```dart
  /// StateBuilder.multi(
  ///   providers: () => (
  ///     user: userProvider.watch,
  ///     loading: loadingField.watch,
  ///   ),
  ///   builder: (context, state, child) {
  ///     return Column(
  ///       children: [
  ///         Text(state.user.name),
  ///         if (state.loading)
  ///           const CircularProgressIndicator(),
  ///         child!,
  ///       ],
  ///     );
  ///   },
  ///   child: const MyFooter(),
  /// );
  /// ```
  ///
  /// A list can be used when working with multiple providers of the same type:
  ///
  /// ```dart
  /// StateBuilder.multi(
  ///   providers: () => mutations
  ///       .map((mutation) => mutation.watch)
  ///       .toList(),
  ///   builder: (context, state, child) {
  ///     final isLoading = state.any((value) => value.isLoading);
  ///
  ///     return isLoading
  ///         ? const CircularProgressIndicator()
  ///         : const YourWidget();
  ///   },
  ///   child: const MyFooter(),
  /// );
  /// ```
  ///
  /// A custom object can be used when you want a named combined state type:
  ///
  /// ```dart
  /// StateBuilder.multi(
  ///   providers: () => CombinedState(
  ///     user: userProvider.watch,
  ///     loading: loadingField.watch,
  ///   ),
  ///   builder: (context, state, child) {
  ///     return Text(state.user.name);
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  const factory StateBuilder.multi({
    Key? key,
    required MultiStateProviders<T> providers,
    required StateWidgetBuilder<T> builder,
    RebuildWhen<T>? rebuildWhen,
    Widget? child,
  }) = _MultiStateBuilder<T>;

  /// Resolves the provider from the current [BuildContext].
  ///
  /// The provider is looked up using [Provider].
  ///
  /// ```dart
  /// StateBuilder.of<MyProvider, MyState>(
  ///   builder: (context, state, child) {
  ///     return MyWidget(state);
  ///   },
  /// )
  /// ```
  static Widget of<P extends StateValueListenable<T>, T>({
    Key? key,
    required StateWidgetBuilder<T> builder,
    RebuildWhen<T>? rebuildWhen,
    Widget? child,
  }) {
    return _StateBuilderOf<P, T>(
      key: key,
      builder: builder,
      rebuildWhen: rebuildWhen,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<RebuildWhen<T>?>.has('rebuildWhen', rebuildWhen))
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }

  /// The public widget name used in diagnostics and assertions.
  String get debugWidgetName => 'StateBuilder<$T>';
}
