part of '../multi_state.dart';

/// Resolves an object managed by Provider and tracks its identity.
///
/// The returned object can implement [StateListenable] itself or expose
/// nested [StateListenable] objects, such as mutations and state fields.
///
/// Must be called inside a supported ProviderKit dependency-collecting
/// callback.
///
/// ```dart
/// final search = of<SearchNotifier>();
///
/// return (
///   saving: search.saveMutation.watch,
///   deleting: search.deleteMutation.watch,
/// );
/// ```
///
/// Resolving an object does not subscribe to its state notifications.
/// Access a [StateListenable] through `.watch` to establish a state
/// dependency.
P of<P extends StateListenable<dynamic>>() {
  return _DependencyTracker.readProvider<P>();
}