library provider_kit_core;

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/errors/error_info_mapper.dart';
import 'package:provider_kit/src/mutation/mutation.dart'
    show MutationConcurrency;
import 'package:provider_kit/src/observer/change.dart';
import 'package:provider_kit/src/observer/notifier_observer.dart';
import 'package:provider_kit/src/utils/flutter_error_reporting.dart';

part '../base/notifier_base.dart';
part 'provider_kit_config.dart';

/// {@template provider_kit.provider_kit_core}
/// Provides global configuration and default behavior for ProviderKit.
///
/// ProviderKit can optionally be configured during application startup using
/// [configure]. Configuration is not required; ProviderKit uses its built-in
/// defaults when [configure] is not called.
///
/// If [configure] is called, it must be called only once. Subsequent calls
/// throw a [StateError].
///
/// The configuration supports:
///
/// - [ErrorInfoMapper] for converting errors into [ErrorInfo] objects.
/// - [NotifierObserver] for observing notifier lifecycle events.
/// - [MutationConcurrency] for setting the default concurrency policy used
///   by mutations.
///
/// The configured [MutationConcurrency] applies to mutations that do not
/// specify their own concurrency policy. It defaults to
/// [MutationConcurrency.parallel], but can be changed to suit your
/// application's needs. Individual mutations can override this default.
///
/// ### Example
///
/// ```dart
/// void main() {
///   ProviderKit.configure(
///     observer: AppNotifierObserver(),
///     mutationConcurrency: MutationConcurrency.ignoreIfBusy,
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
/// - [MutationConcurrency], for available mutation concurrency policies.
/// {@endtemplate}

abstract final class ProviderKit {
  static _ProviderKitConfig _config = _ProviderKitConfig();

  static bool _isConfigured = false;

  /// {@macro provider_kit.provider_kit_core}
  static void configure({
    ErrorInfoMapper? errorInfoMapper,
    NotifierObserver? observer,
    MutationConcurrency mutationConcurrency = MutationConcurrency.parallel,
  }) {
    if (_isConfigured) {
      throw StateError('ProviderKit has already been configured.');
    }

    _config = _ProviderKitConfig(
      errorInfoMapper: errorInfoMapper,
      observer: observer,
      mutationConcurrency: mutationConcurrency,
    );

    if (_config.observer != null) {
      NotifierBase._observer = _config.observer!;
    }

    _isConfigured = true;
  }

  /// Converts an error and its [StackTrace] into [ErrorInfo].
  ///
  /// Uses the [ErrorInfoMapper] configured through [configure].
  ///
  /// If the configured mapper throws an exception, the mapper exception is
  /// reported through Flutter's error reporting mechanism, and a default
  /// [ErrorInfo] is created from the original error instead. This ensures
  /// that a mapper failure does not interrupt ProviderKit's error handling.
  static ErrorInfo resolveErrorInfo(Object error, StackTrace stackTrace) {
    try {
      return _config.errorInfoMapper(error, stackTrace);
    } catch (mapperError, mapperStackTrace) {
      reportErrorToFlutter(
        mapperError,
        mapperStackTrace,
        message:
            'The configured ErrorInfoMapper threw while converting an error.',
      );
      return _ProviderKitConfig._defaultErrorInfoMapper(error, stackTrace);
    }
  }

  /// The default concurrency policy used by mutations.
  static MutationConcurrency get defaultMutationConcurrency =>
      _config.mutationConcurrency;

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
