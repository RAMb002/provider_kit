part of '../multi_state.dart';

/// The result of one listenables evaluation.
///
/// Contains the value produced by the callback, the state dependencies
/// discovered through `.watch`, and the Provider identity dependencies
/// discovered through [of].
///
/// The two dependency collections serve different purposes:
///
/// - [dependencies] contains the [StateListenable] instances subscribed to
///   through [_DependencySubscription].
/// - [providerDependencies] contains the Provider-managed instances whose
///   replacement must be tracked by the owning widget.
final class _DependencyCollection<T> {
  const _DependencyCollection({
    required this.value,
    required this.dependencies,
    required this.providerDependencies,
  });

  /// The combined value produced by the listenables callback.
  final T value;

  /// State dependencies discovered through `.watch`.
  ///
  /// These are synchronized with the active subscriptions through
  /// [_DependencySubscription].
  final Set<StateListenable> dependencies;

  /// Provider identity dependencies discovered through [of].
  ///
  /// The map is keyed by the concrete Provider type. These dependencies
  /// allow the owning widget to detect when a provided instance is replaced.
  final Map<Type, _ProviderDependency> providerDependencies;
}