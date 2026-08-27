library provider_kit_core;

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/observer/change.dart';
import 'package:provider_kit/src/observer/notifier_observer.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/errors/error_info_mapper.dart';

part '../base/notifier_base.dart';
part 'provider_kit_config.dart';

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
      NotifierBase._observer = _config.observer!;
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

  @visibleForTesting
  static void resetForTesting() {
    _config = _ProviderKitConfig();
    _isConfigured = false;
    NotifierBase._observer = const _DefaultNotifierObserver();
  }
}
