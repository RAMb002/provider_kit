import 'package:nested/nested.dart';

/// {@template providerkit-nestedstatelistener}
/// A widget that nests multiple state listeners within a single widget.
///
/// The `NestedStateListener` allows combining multiple types of listeners,
/// such as `StateListener`, `MultiStateListener`, `ViewStateListener`, and `MultiViewStateListener`,
/// enabling efficient state management in a structured manner.
///
/// ### Example Usage:
/// ```dart
/// NestedStateListener(
///   listeners: [
///     StateListener<ExampleProvider, int>(
///       listener: (context, state) {
///         // Handle state changes
///       },
///     ),
///     MultiStateListener(
///       providers: [ExampleProvider(3), ExampleProvider(4)],
///       listener: (context, states) {
///         // Handle state changes
///       },
///     ),
///     ViewStateListener<FeedProvider, List<Item>>(
///       dataStateListener: (data) {
///         // Handle view state changes
///       },
///     ),
///     MultiViewStateListener<List<Item>>(
///       providers: [FeedProvider(), FeedProvider()],
///       dataStateListener: (states) {
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
///   - [MultiStateListener]
///   - [ViewStateListener]
///   - [MultiViewStateListener]
/// - **`child`** (*Required*) **:** The widget wrapped by the listeners, typically the UI component that reacts to state changes.
/// {@endtemplate}
class NestedStateListener extends Nested {
  /// {@macro providerkit-nestedstatelistener}
  NestedStateListener({
    super.key,
    required List<SingleChildWidget> listeners,
    required super.child,
  }) : super(
          children: listeners,
        );
}
