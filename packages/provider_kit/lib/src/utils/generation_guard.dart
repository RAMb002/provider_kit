import 'package:flutter/foundation.dart';

/// Tracks operation generations to identify stale asynchronous callbacks.
///
/// This is an internal ProviderKit utility. It is not part of the public API.
@internal
final class GenerationGuard {
  int _generationToken = 0;

  /// The current generation identifier.
  int get currentGenerationToken => _generationToken;

  /// Starts a new generation and returns its identifier.
  int next() => ++_generationToken;

  /// Returns whether [generationToken] is still current.
  bool isCurrent(int generationToken) => generationToken == _generationToken;

  /// Invalidates the current generation.
  void invalidate() {
    _generationToken++;
  }
}
