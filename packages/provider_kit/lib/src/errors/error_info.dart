/// {@template provider_kit.error_info}
/// Information about an error.
///
/// [ErrorInfo] provides structured information about an error that can be used
/// by application logic or presentation code.
///
/// It contains mapped error information such as a human-readable [message] and
/// an optional machine-readable [code], while the original error and its stack
/// trace remain available separately.
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
  const ErrorInfo({
    required this.message,
    this.code,
  });

  /// A human-readable description of the error.
  final String message;

  /// An optional machine-readable error code.
  final String? code;

  @override
  bool operator ==(Object other) {
    return other is ErrorInfo && other.message == message && other.code == code;
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
