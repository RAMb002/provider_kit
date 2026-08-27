part of 'provider_kit_core.dart';

final class _ProviderKitConfig {
  _ProviderKitConfig({
    ErrorInfoMapper? errorInfoMapper,
    this.observer,
  }) : errorInfoMapper = errorInfoMapper ?? _defaultErrorInfoMapper;

  final ErrorInfoMapper errorInfoMapper;
  final NotifierObserver? observer;

  static ErrorInfo _defaultErrorInfoMapper(
    Object error,
    StackTrace stackTrace,
  ) {
    return ErrorInfo(
      message: error.toString(),
    );
  }
}