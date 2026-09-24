import 'package:flutter/foundation.dart';

/// Internally tracks resources owned by a ProviderKit lifecycle host.
///
/// Resources are registered through [own] and disposed in reverse
/// registration order when [dispose] is called.

@internal
final class ResourceOwner {
  List<void Function()>? _disposeCallbacks;
  bool _disposed = false;

  /// Registers [resource] as owned by this owner.
  ///
  /// [onDispose] is called when the owner is disposed. If the owner has
  /// already been disposed, [resource] is disposed immediately and a
  /// [StateError] is thrown unless [onDispose] itself throws.
  T own<T>(
    T resource, {
    required void Function(T resource) onDispose,
  }) {
    if (_disposed) {
      onDispose(resource);

      throw StateError(
        'Cannot create a ProviderKit resource after its owner has '
        'been disposed.',
      );
    }

    (_disposeCallbacks ??= <void Function()>[]).add(
      () => onDispose(resource),
    );

    return resource;
  }

  /// Disposes all owned resources in reverse registration order.
  ///
  /// Disposal continues even if an individual resource throws. The first
  /// disposal error is rethrown after all resources have had an opportunity
  /// to clean up.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    final callbacks = _disposeCallbacks;
    _disposeCallbacks = null;

    if (callbacks == null) {
      return;
    }

    Object? firstError;
    StackTrace? firstStackTrace;

    for (final dispose in callbacks.reversed) {
      try {
        dispose();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    callbacks.clear();

    if (firstError != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace!,
      );
    }
  }
}
