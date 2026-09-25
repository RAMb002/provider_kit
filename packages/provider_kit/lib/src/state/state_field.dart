import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';

/// {@template provider_kit.state_field}
/// A lightweight observable state field.
///
/// [StateField] stores a single state value and notifies its listeners when
/// the value changes.
///
/// It implements [StateValueListenable], so it can be used directly with
/// ProviderKit state widgets such as [StateBuilder], [StateListener], and
/// [StateConsumer].
///
/// A [StateField] can be created independently:
///
/// ```dart
/// final name = StateField('John');
/// ```
///
/// Listen to changes using [StateListener]:
///
/// ```dart
/// StateListener<String>(
///   provider: name,
///   listener: (context, state) {
///     debugPrint('Name: $state');
///   },
///   child: const SizedBox(),
/// );
/// ```
///
/// Other ProviderKit state widgets, such as [StateBuilder] and
/// [StateConsumer], can also be used with a [StateField].
///
/// When a [StateField] is created directly, you are responsible for disposing
/// it when it is no longer needed:
///
/// ```dart
/// final name = StateField('');
///
/// // Use the field...
///
/// name.dispose();
/// ```
///
/// For fields owned by a [ChangeNotifier], it is highly recommended to use
/// [NotifierResourcesMixin]. The mixin tracks fields created through
/// [field] and disposes them when the notifier is disposed.
///
/// ```dart
/// class LoginController extends ChangeNotifier
///     with NotifierResourcesMixin {
///   late final name = field('');
/// }
/// ```
///
/// This avoids having to manually dispose each [StateField].
/// {@endtemplate}
class StateField<T> extends ChangeNotifier implements StateValueListenable<T> {
  /// {@macro provider_kit.state_field}
  StateField(this._state);

  T _state;
  bool _disposed = false;

  /// Whether this field is still active and can be updated.
  ///
  /// Returns `false` after [dispose] has been called.
  bool get mounted => !_disposed;

  /// The current state value.
  @override
  T get state => _state;

  /// Updates the state and notifies listeners when the value changes.
  ///
  /// Updating a disposed field is considered a programming error in debug
  /// builds and is safely ignored in release builds.
  set state(T value) {
    assert(
      !_disposed,
      'StateField<$T> was used after being disposed.',
    );

    if (_disposed || _state == value) return;

    _state = value;
    notifyListeners();
  }

  /// Disposes this field and releases its listeners.
  ///
  /// A disposed field must not be used again.
  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    super.dispose();
  }
}
