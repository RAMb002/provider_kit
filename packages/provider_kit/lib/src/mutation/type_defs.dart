import 'dart:async';

typedef MutationActionCallback<T> = Future<T> Function();

typedef MutationSuccessCallback<T> = FutureOr<void> Function(T data);

typedef MutationErrorCallback =
    FutureOr<void> Function(Object error, StackTrace stackTrace);
