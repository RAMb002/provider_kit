part of '../async_notifiers.dart';

/// Reports [error] to Flutter with optional diagnostic [message] context.
void _reportErrorToFlutter(
  Object error,
  StackTrace stackTrace, {
  String? message,
}) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'provider_kit',
      context: message == null ? null : ErrorDescription(message),
    ),
  );
}

/// Adds Flutter error reporting to a [Future<void>].
extension _FutureErrorReporting on Future<void> {
  void reportOnError({String? message}) {
    unawaited(
      catchError((Object error, StackTrace stackTrace) {
        _reportErrorToFlutter(error, stackTrace, message: message);
      }),
    );
  }
}
