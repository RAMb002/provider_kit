part of '../multi_state.dart';

/// Represents one active dependency collection scope.
///
/// A scope owns the dependencies discovered during a single listenables
/// evaluation, including state dependencies and Provider identity
/// dependencies.
///
/// The scope is temporary and exists only while its collection callback
/// is being evaluated.
final class _DependencyScope {
  _DependencyScope({
    required this.context,
  });

  /// Context used to resolve Provider-managed listenables.
  ///
  /// Provider objects are resolved using `context.read` during collection.
  /// Their identity dependencies are established separately during the
  /// owning widget's build.
  final BuildContext context;

  /// State dependencies discovered through `.watch`.
  ///
  /// Uses identity-based equality so that distinct listenable instances
  /// are tracked independently, regardless of their equality implementation.
  final Set<StateListenable> dependencies =
      Set<StateListenable>.identity();

  /// Provider identity dependencies discovered through `of<P>()`.
  ///
  /// The concrete Provider type is retained as the map key. Repeated
  /// resolutions of the same Provider type within one collection share
  /// a single identity dependency.
  final Map<Type, _ProviderDependency> providerDependencies =
      <Type, _ProviderDependency>{};
}