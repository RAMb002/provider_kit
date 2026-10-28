import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/widgets/view_state_details.dart';

/// {@template provider_kit.initial_state_callback}
/// A callback invoked for the [InitialState].
/// {@endtemplate}
typedef InitialStateCallback<R> = R Function();

/// {@template provider_kit.loading_state_callback}
/// A callback invoked for the [LoadingState].
///
/// [message] is the optional loading message.
/// [progress] is the optional loading progress value.
/// {@endtemplate}
typedef LoadingStateCallback<R> = R Function(String? message, double? progress);

/// {@template provider_kit.data_state_callback}
/// A callback invoked for the [DataState].
///
/// [data] is the data contained in the state.
/// {@endtemplate}
typedef DataStateCallback<T, R> = R Function(T data);

/// {@template provider_kit.empty_state_callback}
/// A callback invoked for the [EmptyState].
///
/// [message] is the optional empty-state message.
/// [onRefresh] is the optional callback to refresh the operation.
/// {@endtemplate}
typedef EmptyStateCallback<R> =
    R Function(String? message, VoidCallback? onRefresh);

/// {@template provider_kit.error_state_callback}
/// A callback invoked for the [ErrorState].
///
/// [errorInfo] contains mapped information about the error.
/// [error] is the original error.
/// [stackTrace] is the stack trace associated with the error.
/// [onRetry] is the optional retry callback.
/// {@endtemplate}
typedef ErrorStateCallback<R> =
    R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
      VoidCallback? onRetry,
    );

/// {@template provider_kit.initial_state_mapper}
/// A callback that maps an [InitialState] to a value of type [R].
///
/// The [initialState] parameter contains the complete [InitialState] object.
/// {@endtemplate}
typedef InitialStateMapper<R, T> = R Function(InitialState<T> initialState);

/// {@template provider_kit.loading_state_mapper}
/// A callback that maps a [LoadingState] to a value of type [R].
///
/// The [loadingState] parameter contains the complete [LoadingState] object.
/// {@endtemplate}
typedef LoadingStateMapper<R, T> = R Function(LoadingState<T> loadingState);

/// {@template provider_kit.data_state_mapper}
/// A callback that maps a [DataState] to a value of type [R].
///
/// The [dataState] parameter contains the complete [DataState] object.
/// {@endtemplate}
typedef DataStateMapper<R, T> = R Function(DataState<T> dataState);

/// {@template provider_kit.empty_state_mapper}
/// A callback that maps an [EmptyState] to a value of type [R].
///
/// The [emptyState] parameter contains the complete [EmptyState] object.
/// {@endtemplate}
typedef EmptyStateMapper<R, T> = R Function(EmptyState<T> emptyState);

/// {@template provider_kit.error_state_mapper}
/// A callback that maps an [ErrorState] to a value of type [R].
///
/// The [errorState] parameter contains the complete [ErrorState] object.
/// {@endtemplate}
typedef ErrorStateMapper<R, T> = R Function(ErrorState<T> errorState);

// -----------------------------------------------------------------------------
// ViewState listeners
// -----------------------------------------------------------------------------

/// A callback invoked when the view enters its initial state.
///
/// [context] provides access to the current widget-tree context.
typedef InitialStateListener = void Function(BuildContext context);

/// A callback invoked when the view enters a loading state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the loading message prepared for display and the
/// optional progress value.
typedef LoadingStateListener =
    void Function(BuildContext context, LoadingStateDetails details);

/// A callback invoked when the view enters a data state.
///
/// [context] provides access to the current widget-tree context.
/// [data] contains the data produced by the operation.
typedef DataStateListener<T> = void Function(BuildContext context, T data);

/// A callback invoked when the view enters an empty state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the empty-state message prepared for display.
typedef EmptyStateListener =
    void Function(BuildContext context, EmptyStateDetails details);

/// A callback invoked when the view enters an error state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the error information prepared for display, the
/// original error and stack trace, and the optional retry callback.
typedef ErrorStateListener =
    void Function(BuildContext context, ErrorStateDetails details);

// -----------------------------------------------------------------------------
// Custom ViewState builders
// -----------------------------------------------------------------------------

/// Builds the UI for an initial state.
///
/// [context] provides access to the current widget-tree context.
typedef InitialStateBuilder = Widget Function(BuildContext context);

/// Builds the UI for a loading state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the loading message prepared for display and the
/// optional progress value.
typedef LoadingStateBuilder =
    Widget Function(BuildContext context, LoadingStateDetails details);

/// Builds the UI for a data state.
///
/// [context] provides access to the current widget-tree context.
/// [data] contains the data to display.
/// [child] is an optional prebuilt widget supplied by the corresponding
/// ViewStateBuilder or ViewStateConsumer. It can be reused for content that
/// does not depend on the current data.
typedef DataStateBuilder<T> =
    Widget Function(BuildContext context, T data, Widget? child);

/// Builds the UI for an error state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the error information prepared for display, the original
/// error and stack trace, and the optional retry callback.
typedef ErrorStateBuilder =
    Widget Function(BuildContext context, ErrorStateDetails details);

/// Builds the UI for an empty state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the empty-state message prepared for display.
typedef EmptyStateBuilder =
    Widget Function(BuildContext context, EmptyStateDetails details);

// -----------------------------------------------------------------------------
// Default ViewStateWidgetsProvider builders
// -----------------------------------------------------------------------------

/// Builds the default UI for an initial state.
///
/// [context] provides access to the current widget-tree context.
/// [isSliver] indicates whether the resulting widget should be suitable
/// for use in a sliver.
typedef DefaultInitialStateBuilder =
    Widget Function(BuildContext context, bool isSliver);

/// Builds the default UI for a loading state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the loading message prepared for display and the
/// optional progress value.
/// [isSliver] indicates whether the resulting widget should be suitable
/// for use in a sliver.
typedef DefaultLoadingStateBuilder =
    Widget Function(
      BuildContext context,
      LoadingStateDetails details,
      bool isSliver,
    );

/// Builds the default UI for an empty state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the empty-state message prepared for display.
/// [isSliver] indicates whether the resulting widget should be suitable
/// for use in a sliver.
typedef DefaultEmptyStateBuilder =
    Widget Function(
      BuildContext context,
      EmptyStateDetails details,
      bool isSliver,
    );

/// Builds the default UI for an error state.
///
/// [context] provides access to the current widget-tree context.
/// [details] contains the error information prepared for display, the original
/// error and stack trace, and the optional retry callback.
/// [isSliver] indicates whether the resulting widget should be suitable
/// for use in a sliver.
typedef DefaultErrorStateBuilder =
    Widget Function(
      BuildContext context,
      ErrorStateDetails details,
      bool isSliver,
    );
