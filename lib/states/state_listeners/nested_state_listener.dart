// ignore: depend_on_referenced_packages
import 'package:nested/nested.dart';

/// A widget that nests multiple state listeners.
///
/// The [NestedStateListener] class is designed to nest multiple state listeners within a single widget.
/// It allows you to combine different types of listeners and manage them together.
///
/// ### Example Usage:
/// ```dart
/// NestedStateListener(
///   listeners: [
///     StateListener<MyState>(
///       listener: (context, state) {
///         // Handle state changes
///       },
///     ),
///     MultiStateListener(
///       listeners: [
///         StateListener<MyState>(
///           listener: (context, state) {
///             // Handle nested state changes
///           },
///         ),
///       ],
///     ),
///     ViewStateListener<MyData>(
///       dataStateListener: (context, viewState) {
///         // Handle view state changes
///       },
///     ),
///     MultiViewStateListener<MyData>(
///       listeners: [
///         dataStateListener<MyData>(
///           listener: (context, viewState) {
///             // Handle nested view state changes
///           },
///         ),
///       ],
///     ),
///   ],
///   child: MyChildWidget(),
/// )
/// ```
///
/// ### Parameters:
/// - **`listeners`** (*Required*) **:** A list of [SingleChildWidget] listeners. These can be any type of listener, such as:
///   - [StateListener]
///   - [ViewStateListener]
///   - [MultiViewStateListener]
///   - [MultiStateListener]
/// - **`child`** (*Required*) **:** The child widget that will be wrapped by the listeners.
class NestedStateListener extends Nested {
  NestedStateListener({
    super.key,
    required List<SingleChildWidget> listeners,
    required super.child,
  }) : super(
          children: listeners,
        );
}
