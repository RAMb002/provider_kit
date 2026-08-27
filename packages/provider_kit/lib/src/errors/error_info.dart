/// Presentation-friendly information about an error.
///
/// [ErrorInfo] separates information intended for presentation or application
/// logic from the original technical error object.
///
/// ProviderKit keeps the original error and stack trace separately, while
/// [ErrorInfo] provides a stable, simple contract for user-facing error
/// handling.
///
/// Example:
///
/// ```dart
/// const ErrorInfo(
///   message: 'The email or password is incorrect.',
///   code: 'invalid_credentials',
/// );
/// ```
final class ErrorInfo {
  /// Creates error information.
  ///
  /// [message] is the human-readable description of the error.
  ///
  /// [code] is an optional machine-readable identifier that an application can
  /// use when it needs to distinguish between different error conditions.
  const ErrorInfo({
    required this.message,
    this.code,
  });

  /// Human-readable message suitable for presentation.
  ///
  /// Applications can use this value for UI feedback such as snackbars,
  /// dialogs, inline error messages, or other presentation mechanisms.
  final String message;

  /// Optional machine-readable error code.
  ///
  /// ProviderKit does not impose any meaning or format on this value.
  /// Applications may use strings representing their own error taxonomy.
  final String? code;

  @override
  bool operator ==(Object other) {
    return other is ErrorInfo &&
        other.message == message &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(
        message,
        code,
      );

  @override
  String toString() {
    return 'ErrorInfo('
        'message: $message, '
        'code: $code'
        ')';
  }
}