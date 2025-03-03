import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/notifiers/provider_kit.dart';
import 'package:provider_kit/src/notifiers/state_notifier.dart';
import 'package:provider_kit/src/states/states.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';
import 'package:provider_kit/src/view_state_widgets_provider.dart';

class ViewStateBase {
  static bool hasErrorState<T>(List<ViewState<T>> states) =>
      states.any((state) => state is ErrorState<T>);

  static bool hasInitialState<T>(List<ViewState<T>> states) =>
      states.any((state) => state is InitialState<T>);

  static bool hasLoadingState<T>(List<ViewState<T>> states) =>
      states.any((state) => state is LoadingState<T>);

  static bool hasEmptyState<T>(List<ViewState<T>> states) =>
      states.any((state) => state is EmptyState<T>);

  static bool allAreDataState<T>(List<ViewState<T>> states) =>
      states.every((state) => state is DataState<T>);

  static Widget buildInitialWidget(BuildContext context,
      InitialStateBuilder? initialBuilder, bool isSliver) {
    return initialBuilder != null
        ? initialBuilder(isSliver)
        : context.initialStateWidget(isSliver);
  }

  static Widget buildLoadingWidget(
      BuildContext context,
      LoadingStateBuilder? loadingBuilder,
      String? message,
      double? progress,
      bool isSliver) {
    return loadingBuilder != null
        ? loadingBuilder(message, progress, isSliver)
        : context.loadingStateWidget(message, progress, isSliver);
  }

  static Widget buildEmptyWidget(BuildContext context,
      EmptyStateBuilder? emptyBuilder, String? message, bool isSliver) {
    return emptyBuilder != null
        ? emptyBuilder(message, isSliver)
        : context.emptyStateWidget(message, isSliver);
  }

  static void onRetry<T>(List<StateNotifier<ViewState<T>>> providers) {
    for (var provider in providers) {
      final state = provider.state;
      if (state is ErrorState<T>) {
        if (state.onRetry != null) {
          state.onRetry!.call();
        } else if (provider is ProviderKit) {
          (provider as ProviderKit).refresh();
        }
      }
    }
  }

  static double getCombinedLoadingProgress<T>(
          List<LoadingState<T>> loadingStates) =>
      loadingStates
          .map<double>((e) => e.progress ?? 0.0)
          .fold<double>(0.0, (progress, e) => progress + e) /
      loadingStates.length;

  static List<ErrorState<T>> getErrorStates<T>(List<ViewState<T>> states) =>
      states.whereType<ErrorState<T>>().toList();

  static List<LoadingState<T>> getLoadingStates<T>(List<ViewState<T>> states) =>
      states.whereType<LoadingState<T>>().toList();

  static List<EmptyState<T>> getEmptyStates<T>(List<ViewState<T>> states) =>
      states.whereType<EmptyState<T>>().toList();
}
