import 'dart:async';

import 'package:flutter/foundation.dart';

/// Reports [error] to Flutter with optional diagnostic information.
///
/// This is an internal ProviderKit utility for reporting errors consistently
/// through Flutter's error-reporting mechanism.
@internal
void reportErrorToFlutter(
  Object error,
  StackTrace stackTrace, {
  String? message,
  String library = 'provider_kit',
  InformationCollector? informationCollector,
  bool silent = false,
}) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: library,
      context: message == null ? null : ErrorDescription(message),
      informationCollector: informationCollector,
      silent: silent,
    ),
  );
}

/// Adds Flutter error reporting to a [Future<void>].
@internal
extension FutureErrorReporting on Future<void> {
  /// Reports an asynchronous error through Flutter instead of leaving it
  /// unhandled.
  ///
  /// The returned future is intentionally not exposed, making this suitable
  /// for fire-and-forget operations.
  void reportOnError({
    String? message,
    String library = 'provider_kit',
  }) {
    unawaited(
      catchError((Object error, StackTrace stackTrace) {
        reportErrorToFlutter(
          error,
          stackTrace,
          message: message,
          library: library,
        );
      }),
    );
  }
}