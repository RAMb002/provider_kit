import 'package:provider_kit/src/errors/error_info.dart';

/// Converts an arbitrary error into [ErrorInfo].
///
/// The mapper receives both the original [error] and its [StackTrace], allowing
/// applications to inspect the underlying failure and produce presentation-
/// friendly information.
///
/// Example:
///
/// ```dart
/// final ErrorInfoMapper mapper = (error, stackTrace) {
///   return ErrorInfo(
///     message: 'Something went wrong.',
///   );
/// };
/// ```
typedef ErrorInfoMapper = ErrorInfo Function(
  Object error,
  StackTrace stackTrace,
);