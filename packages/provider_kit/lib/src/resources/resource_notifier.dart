import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/resources/notifier_resources_mixin.dart';

/// A [ChangeNotifier] with automatic lifecycle management for ProviderKit
/// resources.
///
/// Extend this class when you want to use ProviderKit resources such as
/// [StateField], [Mutation], [MutationGroup], [Debounce], and [Throttle]
/// without manually adding [NotifierResourcesMixin].
///
/// Resources created through [NotifierResourcesMixin] are automatically
/// disposed when this notifier is disposed.
///
/// The notifier itself still follows the normal [ChangeNotifier] lifecycle.
/// Whoever owns the notifier is responsible for disposing it when it is no
/// longer needed.
///
/// Always call `super.dispose()` when overriding [dispose] so that all owned
/// resources are disposed correctly.
///
/// ```dart
/// class SearchProvider extends ResourceNotifier {
///   late final searchQuery = field('');
///   late final searchMutation = mutation<bool>();
///   late final searchDebounce = debounce(
///     duration: const Duration(milliseconds: 300),
///   );
/// }
/// ```
///
/// For example, when using `ChangeNotifierProvider`, the provider manages the
/// notifier's lifecycle and disposes it when it is removed from the widget
/// tree.
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => SearchProvider(),
///   child: const SearchPage(),
/// );
/// ```
///
/// Use [NotifierResourcesMixin] directly when your notifier already extends
/// another base class.
///
/// `ResourceNotifier` is equivalent to:
///
/// ```dart
/// class MyNotifier extends ChangeNotifier
///     with NotifierResourcesMixin {
/// }
///
/// `ResourceNotifier` is provided as a convenience for the common case where
/// [ChangeNotifier] is the base class.
abstract class ResourceNotifier extends ChangeNotifier
    with NotifierResourcesMixin {}
