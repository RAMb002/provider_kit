import 'package:flutter/widgets.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:provider_kit/src/resources/resource_owner.dart';
import 'package:rate_kit/rate_kit.dart';

/// Provides automatic lifecycle management for ProviderKit resources
/// created by a [State].
///
/// Resources created through this mixin are automatically disposed when
/// the state is disposed.
///
/// {@macro provider_kit.resources_mixin.common}
///
/// ```dart
/// class _SearchPageState extends State<SearchPage>
///     with StateResourcesMixin<SearchPage> {
///   late final searchQuery = field('');
///   late final searchMutation = mutation<bool>();
///   late final searchGroup = mutationGroup<bool>();
///   late final searchDebounce = debounce(
///     duration: const Duration(milliseconds: 300),
///   );
///   late final searchThrottle = throttle();
/// }
/// ```
///
/// {@macro provider_kit.resources_mixin.no_manual_dispose}
///
/// When the [State] is disposed, all resources owned by this mixin are
/// disposed automatically as part of the state's lifecycle.
mixin StateResourcesMixin<T extends StatefulWidget> on State<T> {
  final ResourceOwner _resourceOwner = ResourceOwner();

  late final Debounce _defaultDebounce = debounce();
  late final Throttle _defaultThrottle = throttle();

  /// Creates a [StateField] owned by this state.
  ///
  /// The field is automatically disposed when the state is disposed.
  StateField<TValue> field<TValue>(TValue initialState) {
    return _resourceOwner.own(
      StateField<TValue>(initialState),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// Creates a [Mutation] managed by this mixin.
  ///
  /// The mutation is automatically disposed when the state is disposed.
  Mutation<TValue> mutation<TValue>() {
    return _resourceOwner.own(
      Mutation<TValue>(),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// Creates a [MutationGroup] managed by this mixin.
  ///
  /// The mutation group is automatically disposed when the state is disposed.
  MutationGroup<TValue> mutationGroup<TValue>({
    Set<KeepAliveState> keepAliveStates = const {},
  }) {
    return _resourceOwner.own(
      MutationGroup<TValue>(
        keepAliveStates: keepAliveStates,
      ),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// Creates a [Debounce] managed by this mixin.
  ///
  /// {@macro provider_kit.resources_mixin.debounce_usage}
  ///
  /// The debounce is automatically disposed when the state is disposed.
  Debounce debounce({
    Duration duration = const Duration(milliseconds: 300),
    bool leading = false,
    bool? trailing,
    Duration? maxWait,
  }) {
    return _resourceOwner.own(
      Debounce(
        duration: duration,
        leading: leading,
        trailing: trailing,
        maxWait: maxWait,
      ),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// {@macro provider_kit.resources_mixin.debounce_run_usage}
  ///
  /// The shared debounce is created lazily on first use and is automatically
  /// disposed when the state is disposed.
  void debounceRun(
    void Function() operation, {
    Object? key,
    Duration? duration,
  }) {
    _defaultDebounce.run(
      operation,
      key: key,
      duration: duration,
    );
  }

  /// Creates a [Throttle] managed by this mixin.
  ///
  /// {@macro provider_kit.resources_mixin.throttle_usage}
  ///
  /// The throttle is automatically disposed when the state is disposed.
  Throttle throttle({
    Duration duration = const Duration(milliseconds: 300),
    bool? leading,
    bool trailing = false,
  }) {
    return _resourceOwner.own(
      Throttle(
        duration: duration,
        leading: leading,
        trailing: trailing,
      ),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// {@macro provider_kit.resources_mixin.throttle_run_usage}
  ///
  /// The shared throttle is created lazily on first use and is automatically
  /// disposed when the state is disposed.
  void throttleRun(
    void Function() operation, {
    Object? key,
  }) {
    _defaultThrottle.run(
      operation,
      key: key,
    );
  }

  @override
  void dispose() {
    try {
      _resourceOwner.dispose();
    } finally {
      super.dispose();
    }
  }
}
