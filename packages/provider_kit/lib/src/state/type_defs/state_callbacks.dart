import 'package:flutter/widgets.dart';

/// A callback that determines whether a listener should be called based on
/// the previous and current state.
///
/// [previous] is the previous state.
/// [next] is the current state.
typedef ListenWhen<T> = bool Function(T previous, T next);

/// A callback that determines whether a builder should rebuild based on
/// the previous and current state.
///
/// [previous] is the previous state.
/// [next] is the current state.
typedef RebuildWhen<T> = bool Function(T previous, T next);

/// A callback that returns the combined state used by a multi-state widget.
///
/// State sources are accessed through `.watch` inside the callback so
/// ProviderKit can track the dependencies automatically.
typedef MultiStateProviders<T> = T Function();

/// A callback that builds a widget based on the current state.
///
/// [context] provides the build context.
/// [state] provides the current state.
/// [child] provides an optional child widget.
typedef StateWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T state,
  Widget? child,
);

/// A callback invoked when the state changes.
///
/// [context] provides the build context.
/// [state] provides the current state.
typedef ListenerCallback<T> = void Function(
  BuildContext context,
  T state,
);