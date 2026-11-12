part of '../multi_state.dart';

/// Represents a typed dependency resolved from Provider.
abstract interface class _ProviderDependency {
  /// The concrete Provider registration type.
  Type get providerType;

  /// The currently resolved listenable instance.
  Object get identity;

  /// Establishes an inherited dependency on the Provider instance.
  ///
  /// Must be called during the owning widget's build.
  void dependOn(BuildContext context);
}

/// A Provider dependency that retains its concrete type [P].
///
/// The identity comparison deliberately uses [identical], so replacing
/// a notifier is detected independently of its equality implementation.
final class _TypedProviderDependency<P extends StateListenable<dynamic>>
    implements _ProviderDependency {
  const _TypedProviderDependency(this.listenable);

  final P listenable;

  @override
  Type get providerType => P;

  @override
  Object get identity => listenable;

  @override
  void dependOn(BuildContext context) {
    context.select<P, bool>((provided) => identical(provided, listenable));
  }
}
