part of '../multi_state.dart';

/// Represents one active dependency collection scope.
///
/// A scope owns the dependencies discovered during a single providers
/// evaluation.
final class _DependencyScope {
  _DependencyScope({required this.dependencies});

  /// Dependencies discovered while this scope is active.
  final Set<StateListenable> dependencies;
}
