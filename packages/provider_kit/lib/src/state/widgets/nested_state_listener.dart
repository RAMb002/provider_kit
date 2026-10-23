import 'package:nested/nested.dart';

/// {@template provider_kit.nested_state_listener}
/// A widget that nests multiple state listeners within a single widget.
///
/// The `NestedStateListener` allows combining multiple types of listeners,
/// such as `StateListener`, `StateListener.multi`, `ViewStateListener`, and `ViewStateListener.multi`,
/// allowing multiple listeners to be nested within a single widget.
///
/// ### Example Usage:
/// ```dart
/// NestedStateListener(
///   listeners: [
///     StateListener(
///       listenable: counterNotifier
///       listener: (context, state) {
///         // Handle state changes
///       },
///     ),
///     StateListener.multi(
///       listenables: () => (
///         first: firstNotifier.watch,
///         second: secondNotifier.watch,
///       ),
///       listener: (context, state) {
///         // Handle state changes
///       },
///     ),
///     ViewStateListener.of<FeedProvider, List<Item>>(
///       dataStateListener: (data) {
///         // Handle view state changes
///       },
///     ),
///     ViewStateListener.multi(
///       listenables: () => (
///         first: firstNotifier.watch,
///         second: secondNotifier.watch,
///       ),
///       dataStateListener: (state) {
///         // Handle state changes
///       },
///     ),
///   ],
///   child: MyChildWidget(),
/// )
/// ```
///
/// ### Parameters:
/// - **`listeners`** (*Required*) **:** A list of [SingleChildWidget] listeners, which can include:
///   - [StateListener]
///   - [StateListener.multi]
///   - [ViewStateListener]
///   - [ViewStateListener.multi]
/// - **`child`** (*Required*) **:** The widget wrapped by the listeners, typically the UI component that reacts to state changes.
/// {@endtemplate}
class NestedStateListener extends Nested {
  /// {@macro provider_kit.nested_state_listener}
  NestedStateListener({
    super.key,
    required List<SingleChildWidget> listeners,
    required super.child,
  }) : super(children: listeners);
}
