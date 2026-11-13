import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/base/state_listenable.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiStateEngine;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/state_engine.dart';

part 'multi_state_builder.dart';
part 'state_builder_base.dart';
part 'state_builder_impl.dart';
part 'state_builder_of.dart';

/// {@template provider_kit.state_builder}
/// A widget that rebuilds its UI when its state changes.
///
/// - Use [StateBuilder] to rebuild from a single listenable.
/// - Use [StateBuilder.of] to retrieve a listenable from the widget tree.
/// - Use [StateBuilder.multi] to combine state from multiple listenables.
///
/// The builder is called when the state changes and [rebuildWhen] allows the
/// rebuild. The optional [child] is preserved across rebuilds and can be used
/// for a subtree that does not depend on the state.
///
/// ### Example Usage:
/// ```dart
/// StateBuilder(
///   listenable: myStateListenable,
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return Container();
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// );
/// ```
///
/// If the listenable is available in the widget tree (e.g., exposed through
/// a provider from the `provider` package), you can use [StateBuilder.of]
/// to retrieve and listen to it:
///
/// ```dart
/// StateBuilder.of<MyStateListenable, MyState>(
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return Container();
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// );
/// ```
///
/// When retrieving a nested listenable from a provider, use
/// [selectListenable]. The selector is reevaluated when the provider
/// dependency changes, allowing ProviderKit to subscribe to the nested
/// listenable belonging to the updated object:
///
/// ```dart
/// StateBuilder.of<MyStateListenable, MutationState<void>>(
///   selectListenable: (notifier) => notifier.saveMutation,
///   builder: (context, state, child) {
///     // React to mutation state changes.
///   },
///   child: const MyPage(),
/// );
/// ```
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
  /// by the `listenables` callback.
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
    required StateListenable<T> listenable,
    required StateWidgetBuilder<T> builder,
    RebuildWhen<T>? rebuildWhen,
    Widget? child,
  }) = _StateBuilder<T>;

  /// {@template provider_kit.state_builder.multi}
  /// ### Listening to Multiple Listenables
  ///
  /// Use [StateBuilder.multi] when a builder depends on the state of multiple
  /// listenables. The [listenables] callback builds a single combined state by
  /// reading listenables state through `.watch`. ProviderKit automatically tracks
  /// every watched listenable and re-evaluates the combined state whenever any of
  /// those listenables change.
  ///
  /// The combined state returned by [listenables] is passed to [builder] and
  /// [rebuildWhen]. It can be any Dart type, including a record, list, or custom
  /// object.
  ///
  /// A record can be used when you want named values:
  ///
  /// ```dart
  /// StateBuilder.multi(
  ///   listenables: () => (
  ///     user: userNotifier.watch,
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
  /// A list can be used when working with multiple listenables of the same type:
  ///
  /// ```dart
  /// StateBuilder.multi(
  ///   listenables: () => mutations
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
  ///   listenables: () => CombinedState(
  ///     user: userNotifier.watch,
  ///     loading: loadingField.watch,
  ///   ),
  ///   builder: (context, state, child) {
  ///     return Text(state.user.name);
  ///   },
  /// );
  /// ```
  ///
  /// ### Resolving Listenables from Provider
  ///
  /// When listenables are exposed through providers from the `provider`
  /// package, use `of<T>().watch` inside the `listenables` callback to
  /// resolve and watch them.
  ///
  /// This also tracks the provider dependency, so the collection is
  /// re-evaluated when the provider dependency changes, such as when
  /// a provider supplies a different notifier.
  ///
  /// ```dart
  /// StateBuilder.multi(
  ///   listenables: () => (
  ///     user: of<UserNotifier>().watch,
  ///     settings: of<SettingsNotifier>().watch,
  ///   ),
  ///   builder: (context, state, child) {
  ///     return Text(state.user.name);
  ///   },
  ///   child: const MyPage(),
  /// );
  /// ```
  /// {@endtemplate}
  const factory StateBuilder.multi({
    Key? key,
    required MultiStateListenables<T> listenables,
    required StateWidgetBuilder<T> builder,
    RebuildWhen<T>? rebuildWhen,
    Widget? child,
  }) = _MultiStateBuilder<T>;

  /// {@macro provider_kit.state_widget.of}
  ///
  /// Listen directly to a provided StateListenable:
  ///
  /// ```dart
  /// StateBuilder.of<MyStateListenable, MyState>(
  ///   builder: (context, state, child) {
  ///     return MyWidget(state);
  ///   },
  /// );
  /// ```
  /// Listen to a nested listenable from a provider:
  ///
  /// ```dart
  /// StateBuilder.of(
  ///   selectListenable: (MyStateListenable notifier) => notifier.saveMutation,
  ///   builder: (context, state, child) {
  ///     return MyWidget(state);
  ///   },
  ///   child: const MyPage(),
  /// );
  /// ```
  static of<P extends StateListenable<T>, T>({
    Key? key,
    required StateWidgetBuilder<T> builder,
    SelectStateListenable<P, T>? selectListenable,
    RebuildWhen<T>? rebuildWhen,
    Widget? child,
  }) {
    return _StateBuilderOf<P, T>(
      key: key,
      selectListenable: selectListenable,
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
