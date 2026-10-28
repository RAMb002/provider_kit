import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// Presentation details for a loading state.
///
/// Used by ProviderKit's view-state builders, listeners, and consumers,
/// including their multi-state variants.
///
/// The [message] is resolved using the configured
/// `ViewStateWidgetsProvider.messageResolver` before being passed to
/// widget callbacks. If no resolver handles the message, the original
/// message is retained.
@immutable
final class LoadingStateDetails {
  /// Creates loading-state presentation details.
  const LoadingStateDetails({this.message, this.progress});

  /// The loading message prepared for display.
  ///
  /// May be `null` if the loading state has no message.
  final String? message;

  /// The optional progress of the loading operation.
  final double? progress;
}

/// Presentation details for an empty state.
///
/// Used by ProviderKit's view-state builders, listeners, and consumers,
/// including their multi-state variants.
///
/// The [message] is resolved using the configured
/// `ViewStateWidgetsProvider.messageResolver` before being passed to
/// widget callbacks. If no resolver handles the message, the original
/// message is retained.
@immutable
final class EmptyStateDetails {
  /// Creates empty-state presentation details.
  const EmptyStateDetails({this.message});

  /// The empty-state message prepared for display.
  ///
  /// May be `null` if the empty state has no message.
  final String? message;
}

/// Presentation details for an error state.
///
/// Used by ProviderKit's view-state builders, listeners, and consumers,
/// including their multi-state variants.
///
/// The [errorInfo] contains the error information prepared for display.
/// Its message may be localized, but the original [ErrorState] and its
/// [ErrorInfo] remain unchanged.
@immutable
final class ErrorStateDetails {
  /// Creates error-state presentation details.
  const ErrorStateDetails({
    required this.errorInfo,
    required this.error,
    required this.stackTrace,
    this.onRetry,
  });

  /// The error information prepared for display.
  ///
  /// The message is resolved using the configured
  /// `ViewStateWidgetsProvider.messageResolver`, while the original
  /// error code is preserved.
  final ErrorInfo errorInfo;

  /// The original error that caused the state.
  final Object error;

  /// The stack trace associated with [error].
  final StackTrace stackTrace;

  /// The callback to retry the operation, if available.
  final VoidCallback? onRetry;

  /// {@macro provider_kit.error_info.message}
  String? get message => errorInfo.message;

  /// {@macro provider_kit.error_info.code}
  String? get code => errorInfo.code;
}
