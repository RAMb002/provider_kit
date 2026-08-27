import 'package:provider_kit/src/base/notifier_base.dart';
import 'package:provider_kit/src/base/observer/notifier_observer.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/errors/error_info_mapper.dart';

abstract final class ProviderKit {
  static _ProviderKitConfig _config = _ProviderKitConfig();

  static bool _isConfigured = false;

  static void configure(
      {ErrorInfoMapper? errorInfoMapper, NotifierObserver? observer}) {
    if (_isConfigured) {
      throw StateError(
        'ProviderKit has already been configured.',
      );
    }

    _config = _ProviderKitConfig(
      errorInfoMapper: errorInfoMapper,
      observer: observer,
    );

    if (_config.observer != null) {
      NotifierBase.observer = _config.observer!;
    }

    _isConfigured = true;
  }

  static ErrorInfo resolveErrorInfo(
    Object error,
    StackTrace stackTrace,
  ) {
    return _config.errorInfoMapper(
      error,
      stackTrace,
    );
  }
}

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
