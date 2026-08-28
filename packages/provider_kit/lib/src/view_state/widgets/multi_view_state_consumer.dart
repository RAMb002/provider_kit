part of '../view_state_widgets.dart';

/// {@template provider_kit.multi_view_state_consumer}
/// A widget that combines both listening to and building based on the states of multiple [ViewStateNotifier]s.
///
/// The [MultiViewStateConsumer] widget is used to perform actions and build its child widget
/// in response to state changes in multiple [ViewStateNotifier]s. It ensures that the appropriate
/// listener and builder are called based on the current states.
///
/// ### Logic:
/// - If there is at least one `ErrorState` in the list of providers, the listener and builder will be set to `ErrorState`. This means that if any of the states in the list is an `ErrorState`, the `errorStateListener` and `errorBuilder` will be invoked.
/// - If none of the states is an `ErrorState`, the listener and builder will check for `InitialState`. If any of the states is an `InitialState`, the `initialStateListener` and `initialBuilder` will be invoked.
/// - If none of the states is an `InitialState`, the listener and builder will check for `LoadingState`. If any of the states is a `LoadingState`, the `loadingStateListener` and `loadingBuilder` will be invoked.
/// - If none of the states is a `LoadingState`, the listener and builder will check for `EmptyState`. If any of the states is an `EmptyState`, the `emptyStateListener` and `emptyBuilder` will be invoked.
/// - If all states are `DataState<DataType>`, the listener and builder will be set to `DataState`. This means that if all the states in the list are `DataState<DataType>`, the `dataStateListener` and `dataBuilder` will be invoked.
/// - If the user wants to avoid showing `EmptyState` just because one of them is empty while the others are `DataState`, the user should not use `EmptyState` in their provider logic and handle empty states manually inside the `DataState` builder.
///
/// If the user does not supply a builder or listener for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// ### Example Usage:
/// ```dart
/// MultiViewStateConsumer<DataType>(
///   providers: [provider1, provider2], // Required
///   initialBuilder: (isSliver) {
///     // Build your widget tree for InitialState
///     return Container();
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     // Build your widget tree for LoadingState
///     return Container();
///   },
///   emptyBuilder: (message, isSliver) {
///     // Build your widget tree for EmptyState
///     return Container();
///   },
///   errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
///     // Build your widget tree for ErrorState
///     return Container();
///   },
///   dataBuilder: (data) {
///     // Build your widget tree for DataState<DataType>
///     return Container();
///   },
///   initialStateListener: () {
///     // Handle InitialState
///   },
///   loadingStateListener: (message, progress) {
///     // Handle LoadingState
///   },
///   emptyStateListener: (message) {
///     // Handle EmptyState
///   },
///   errorStateListener: (errorInfo, error, stackTrace, onRetry) {
///     // Handle ErrorState
///   },
///   dataStateListener: (data) {
///     // Handle DataState<DataType>
///   },
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   callListenerOnInit: true, // Optional, default is false
///   isSliver: false, // Optional, default is false
/// )
/// ```
/// {@endtemplate}

class MultiViewStateConsumer<T> extends MultiStateConsumer<ViewState<T>> {
  final InitialStateBuilder? initialBuilder;
  final LoadingStateBuilder? loadingBuilder;
  final EmptyStateBuilder? emptyBuilder;
  final ErrorStateBuilder? errorBuilder;
  final MultiDataStateBuilder<List<DataState<T>>> dataBuilder;
  final bool isSliver;

  final InitialStateListener? initialStateListener;
  final LoadingStateListener? loadingStateListener;
  final EmptyStateListener? emptyStateListener;
  final ErrorStateListener? errorStateListener;
  final DataStateListener<List<DataState<T>>>? dataStateListener;

  /// {@macro provider_kit.multi_view_state_consumer}
  MultiViewStateConsumer(
      {super.key,
      required List<ViewStateNotifier<T>> providers,
      this.initialBuilder,
      this.loadingBuilder,
      this.emptyBuilder,
      this.errorBuilder,
      required this.dataBuilder,
      super.rebuildWhen,
      this.initialStateListener,
      this.loadingStateListener,
      this.emptyStateListener,
      this.errorStateListener,
      this.dataStateListener,
      super.listenWhen,
      super.callListenerOnInit,
      this.isSliver = false})
      : super(
          providers: providers,
          builder: (context, states, child) =>
              MultiViewStateBuilder._multiViewStateBuilder(
                  states,
                  providers,
                  errorBuilder,
                  context,
                  isSliver,
                  initialBuilder,
                  loadingBuilder,
                  emptyBuilder,
                  dataBuilder),
          listener: (context, states) =>
              MultiViewStateListener._multiStateListener(
                  states,
                  providers,
                  errorStateListener,
                  initialStateListener,
                  loadingStateListener,
                  emptyStateListener,
                  dataStateListener),
        );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<InitialStateBuilder?>.has(
          'initialBuilder', initialBuilder))
      ..add(ObjectFlagProperty<LoadingStateBuilder?>.has(
          'loadingBuilder', loadingBuilder))
      ..add(ObjectFlagProperty<EmptyStateBuilder?>.has(
          'emptyBuilder', emptyBuilder))
      ..add(ObjectFlagProperty<ErrorStateBuilder?>.has(
          'errorBuilder', errorBuilder))
      ..add(ObjectFlagProperty<MultiDataStateBuilder<List<DataState<T>>>>.has(
          'dataBuilder', dataBuilder))
      ..add(
          DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false))
      ..add(ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener', initialStateListener))
      ..add(ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener', loadingStateListener))
      ..add(ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener', emptyStateListener))
      ..add(ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener', errorStateListener))
      ..add(ObjectFlagProperty<DataStateListener<List<DataState<T>>>?>.has(
          'dataStateListener', dataStateListener));
  }
}
