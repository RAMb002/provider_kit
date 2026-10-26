/// {@template provider_kit.error_info}
/// Information about an error.
///
/// [ErrorInfo] provides structured information about an error that can be used
/// by application logic or presentation code.
///
/// [message] may contain literal text or a localization key. When an error
/// is displayed through ProviderKit's view-state widgets, the message is
/// resolved using the configured
/// `ViewStateWidgetsProvider.messageResolver`.
///
/// [code] optionally provides a machine-readable identifier for the error.
///
///
/// ### Example
///
/// ```dart
/// const ErrorInfo(
///   message: 'The email or password is incorrect.',
///   code: 'invalid_credentials',
/// );
/// ```
/// {@endtemplate}
final class ErrorInfo {
  /// {@macro provider_kit.error_info}
  const ErrorInfo({required this.message, this.code});

  /// The message associated with the error.
  ///
  /// It may contain literal text or a localization key. ProviderKit's
  /// view-state widgets resolve it for display using the configured
  /// `ViewStateWidgetsProvider.messageResolver`
  final String message;

  /// An optional machine-readable error code.
  final String? code;

  @override
  bool operator ==(Object other) {
    return other is ErrorInfo && other.message == message && other.code == code;
  }

  @override
  int get hashCode => Object.hash(message, code);

  @override
  String toString() {
    return 'ErrorInfo('
        'message: $message, '
        'code: $code'
        ')';
  }
}
