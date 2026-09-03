library;

import 'dart:async';

import 'package:flutter/foundation.dart';

part 'debounce_key.dart';
part 'debounce_mixin.dart';
part 'internal/debounce_impl.dart';
part 'internal/debounce_registry.dart';

/// {@template provider_kit.debounce}
/// Delays execution until no new calls occur within the given duration.
///
/// Calling [run] again replaces any pending operation and starts the
/// debounce delay again.
///
/// The default duration is 300 milliseconds.
///
/// ```dart
/// final debounce = Debounce();
///
/// debounce.run(() {
///   search();
/// });
///
/// // Check whether an operation is waiting for the debounce delay.
/// final isPending = debounce.isPending;
///
/// // Cancels the pending operation.
/// debounce.cancel();
///
/// // Always dispose when the instance is no longer needed.
/// debounce.dispose();
/// ```
///
/// {@endtemplate}
class Debounce {
  /// {@macro provider_kit.debounce}
  Debounce() : _impl = _DebounceImpl();

  final _DebounceImpl _impl;

  /// Schedules [operation] to run after the debounce duration.
  ///
  /// If called again before the duration has passed, the previous scheduled
  /// operation is replaced and the timer starts again.
  ///
  /// The default duration is 300 milliseconds.
  void run(
    void Function() operation, {
    Duration duration = _defaultDuration,
  }) {
    _impl.run(
      operation,
      duration: duration,
    );
  }

  /// Whether an operation is currently waiting to be executed.
  bool get isPending => _impl.isPending;

  /// Cancels the pending operation.
  ///
  /// This debounce remains active and can be used again with [run].
  void cancel() {
    _impl.cancel();
  }

  /// Disposes this debounce and prevents it from being used again.
  ///
  /// Any pending operation will not be executed.
  void dispose() {
    _impl.dispose();
  }
}

const Duration _defaultDuration = Duration(milliseconds: 300);
