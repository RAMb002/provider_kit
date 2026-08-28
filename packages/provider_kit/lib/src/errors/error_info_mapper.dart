import 'package:provider_kit/src/errors/error_info.dart';

/// Converts an error into an [ErrorInfo].
///
/// The mapper receives the original [error] and its [StackTrace], allowing
/// applications to inspect the failure and return structured error
/// information.
///
/// ### Example
///
/// ```dart
/// final ErrorInfoMapper mapper = (error, stackTrace) {
///   return ErrorInfo(
///     message: 'Something went wrong.',
///     code: 'unknown_error',
///   );
/// };
/// ```
typedef ErrorInfoMapper = ErrorInfo Function(
  Object error,
  StackTrace stackTrace,
);