part of '../multi_state.dart';

/// The result of one providers evaluation.
///
/// Contains the value produced by the providers callback and all dependencies
/// accessed during that evaluation.
final class _DependencyCollection<T> {
  const _DependencyCollection({
    required this.value,
    required this.dependencies,
  });

  /// The value produced by the providers callback.
  final T value;

  /// The dependencies discovered during the providers evaluation.
  final Set<StateValueListenable> dependencies;
}