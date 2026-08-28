part of 'provider_kit_core.dart';

final class _ProviderKitConfig {
  _ProviderKitConfig({
    ErrorInfoMapper? errorInfoMapper,
    this.observer,
  }) : errorInfoMapper = errorInfoMapper ?? _defaultErrorInfoMapper;

  /// Converts errors into [ErrorInfo] instances.
  ///
  /// Uses the default mapper when no custom mapper is configured.
  final ErrorInfoMapper errorInfoMapper;

  /// The global observer used to monitor notifier lifecycle events.
  final NotifierObserver? observer;

  /// Creates the default [ErrorInfo] for an unhandled error.
  ///
  /// The default implementation uses [Object.toString] as the error message.
  static ErrorInfo _defaultErrorInfoMapper(
    Object error,
    StackTrace stackTrace,
  ) {
    return ErrorInfo(
      message: error.toString(),
    );
  }
}
