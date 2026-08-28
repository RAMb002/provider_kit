library provider_kit_core;

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/errors/error_info_mapper.dart';
import 'package:provider_kit/src/observer/change.dart';
import 'package:provider_kit/src/observer/notifier_observer.dart';

part '../base/notifier_base.dart';
part 'provider_kit_config.dart';

/// {@template provider_kit.provider_kit_core}
/// Provides global configuration and error-handling behavior for ProviderKit.
///
/// Configure [ProviderKit] once during application startup using [configure].
/// The configuration can include an [ErrorInfoMapper] for converting errors
/// into [ErrorInfo] objects and a [NotifierObserver] for observing notifier
/// lifecycle events.
///
/// ### Example
///
/// A common use case is converting authentication errors into
/// a consistent [ErrorInfo] representation:
///
/// ```dart
/// void main() {
///   ProviderKit.configure(
///     observer: MyNotifierObserver(),
///     errorInfoMapper: (error, stackTrace) {
///       if (error is AuthException) {
///         return ErrorInfo(
///           message: error.message ?? 'Authentication failed.',
///           code: error.code,
///         );
///       }
///
///       return ErrorInfo(
///         message: error.toString(),
///       );
///     },
///   );
///
///   runApp(const MyApp());
/// }
/// ```
///
/// Once configured, errors handled by ProviderKit components can use the
/// mapped [ErrorInfo] automatically.
///
/// See also:
/// - [ErrorInfoMapper], for customizing error mapping.
/// - [NotifierObserver], for observing notifier lifecycle events.
/// {@endtemplate}

abstract final class ProviderKit {
  static _ProviderKitConfig _config = _ProviderKitConfig();

  static bool _isConfigured = false;

  /// {@macro provider_kit.provider_kit_core}
  static void configure({
    ErrorInfoMapper? errorInfoMapper,
    NotifierObserver? observer,
  }) {
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

  /// Converts an error and its [StackTrace] into [ErrorInfo].
  ///
  /// The [ErrorInfoMapper] configured through [configure] is used to perform
  /// the conversion.
  static ErrorInfo resolveErrorInfo(
    Object error,
    StackTrace stackTrace,
  ) {
    return _config.errorInfoMapper(
      error,
      stackTrace,
    );
  }

  /// Resets ProviderKit's global configuration for testing.
  ///
  /// This method is strictly intended for test code and should not be used by
  /// application code.
  @visibleForTesting
  static void resetForTesting() {
    _config = _ProviderKitConfig();
    _isConfigured = false;
    NotifierBase._observer = const _DefaultNotifierObserver();
  }
}
