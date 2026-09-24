import 'package:flutter/foundation.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:provider_kit/src/resources/resource_owner.dart';
import 'package:rate_kit/rate_kit.dart';

/// Provides automatic lifecycle management for ProviderKit resources
/// created by a [ChangeNotifier].
///
/// Resources created through this mixin are automatically disposed when
/// the notifier is disposed.
///
/// {@template provider_kit.resources_mixin.common}
/// Owned resources must be declared with `late final`.
/// Resources are initialized lazily when they are first accessed.
///
/// Supported resources:
///
/// - [Mutation]
/// - [MutationGroup]
/// - [Debounce]
/// - [Throttle]
///
/// For [Debounce] and [Throttle], use [debounce] and [throttle] when you need
/// a dedicated resource, or [debounceRun] and [throttleRun] for simpler usage
/// with an internally managed shared resource.
/// {@endtemplate}
///
/// ```dart
/// class SearchProvider extends ChangeNotifier
///     with NotifierResourcesMixin {
///   late final searchMutation = mutation<bool>();
///
///   late final searchDebounce = debounce(
///     duration: const Duration(milliseconds: 300),
///   );
/// }
/// ```
///
/// {@template provider_kit.resources_mixin.no_manual_dispose}
/// No manual `dispose()` call is required for the resources:
///
/// ```dart
/// // ❌ Not needed.
/// @override
/// void dispose() {
///   searchMutation.dispose();
///   searchDebounce.dispose();
///   super.dispose();
/// }
/// ```
/// {@endtemplate}
///
/// When using the `provider` package, `ChangeNotifierProvider` automatically
/// disposes a notifier created by its `create` callback when the provider is
/// removed from the widget tree. The resources owned by this mixin are then
/// disposed automatically as part of the notifier's lifecycle.
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => SearchProvider(),
///   child: const SearchPage(),
/// );
/// ```
mixin NotifierResourcesMixin on ChangeNotifier {
  final ResourceOwner _resourceOwner = ResourceOwner();

  late final Debounce _defaultDebounce = debounce();
  late final Throttle _defaultThrottle = throttle();

  /// Creates a [Mutation] owned by this notifier.
  ///
  /// The mutation is automatically disposed when the notifier is disposed.
  Mutation<T> mutation<T>() {
    return _resourceOwner.own(
      Mutation<T>(),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// Creates a [MutationGroup] owned by this notifier.
  ///
  /// The mutation group is automatically disposed when the notifier is
  /// disposed.
  MutationGroup<T> mutationGroup<T>({
    Set<KeepAliveState> keepAliveStates = const {},
  }) {
    return _resourceOwner.own(
      MutationGroup<T>(
        keepAliveStates: keepAliveStates,
      ),
      onDispose: (resource) => resource.dispose(),
    );
  }

  /// {@template provider_kit.resources_mixin.debounce_usage}
  /// Use this when you need a dedicated [Debounce] instance and direct access
  /// to its API.
  ///
  /// ```dart
  /// late final searchDebounce = debounce();
  ///
  /// searchDebounce.run(() => search());
  /// ```
  ///
  /// Use [debounceRun] for simpler usage when you do not need direct access
  /// to the [Debounce] instance.
  /// {@endtemplate}
  ///
  /// Creates a [Debounce] owned by this notifier.
  ///
  /// The debounce is automatically disposed when the notifier is disposed.
  ///
  /// {@macro provider_kit.resources_mixin.debounce_usage}
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

  /// {@template provider_kit.resources_mixin.debounce_run_usage}
  /// Runs [operation] using a shared [Debounce].
  ///
  /// Use this for simple debounce operations when you do not need direct
  /// access to a [Debounce] instance.
  ///
  /// ```dart
  /// debounceRun(() => search());
  /// ```
  ///
  /// Calls without a [key] share the same debounce state. Providing different
  /// keys creates independent debounce operations.
  /// {@endtemplate}
  ///
  /// The shared debounce is created lazily on first use and is automatically
  /// disposed when the notifier is disposed.
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

  /// {@template provider_kit.resources_mixin.throttle_usage}
  /// Use this when you need a dedicated [Throttle] instance and direct access
  /// to its API.
  ///
  /// ```dart
  /// late final submitThrottle = throttle();
  ///
  /// submitThrottle.run(() => submit());
  /// ```
  ///
  /// Use [throttleRun] for simpler usage when you do not need direct access
  /// to the [Throttle] instance.
  /// {@endtemplate}
  ///
  /// Creates a [Throttle] owned by this notifier.
  ///
  /// The throttle is automatically disposed when the notifier is disposed.
  ///
  /// {@macro provider_kit.resources_mixin.throttle_usage}
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

  /// {@template provider_kit.resources_mixin.throttle_run_usage}
  /// Runs [operation] using a shared [Throttle].
  ///
  /// Use this for simple throttle operations when you do not need direct
  /// access to a [Throttle] instance.
  ///
  /// ```dart
  /// throttleRun(() => submit());
  /// ```
  ///
  /// Calls without a [key] share the same throttle state. Providing different
  /// keys creates independent throttle operations.
  /// {@endtemplate}
  ///
  /// The shared throttle is created lazily on first use and is automatically
  /// disposed when the notifier is disposed.
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