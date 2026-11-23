import 'package:example/gen/assets.gen.dart';
import 'package:example/widgetbook_catalog/shared/code_preview.dart';
import 'package:example/widgets/mutations/mutation/direct_listenable.dart';
import 'package:example/widgets/mutations/mutation/provider_select.dart';
import 'package:example/widgets/mutations/mutation_group.dart';
import 'package:widgetbook/widgetbook.dart';

// Import CodePreview and WidgetbookSourceFile from your existing shared file.

WidgetbookComponent mutationComponent() {
  return WidgetbookComponent(
    name: 'Mutation',
    isInitiallyExpanded: false,
    useCases: [
      WidgetbookUseCase(
        name: 'Direct Listenable',
        builder: (context) => CodePreview(
          title: 'Mutation - Direct Listenable',
          description:
              'Pass a locally owned Mutation directly to State Widgets.',
          preview: const MutationDirectExample(),
          sourceFiles: [
            WidgetbookSourceFile(
              Assets.lib.widgets.mutations.mutation.directListenable,
            ),
            WidgetbookSourceFile(
              Assets.lib.widgets.shared.notifiers.feedbackNotifier,
            ),
          ],
        ),
      ),
      WidgetbookUseCase(
        name: 'Provider Integration',
        builder: (context) => CodePreview(
          title: 'Mutation - Provider Integration',
          description: 'Resolve a Mutation from the Provider tree using '
              '.select on State Widgets.',
          preview: const MutationSelectExample(),
          sourceFiles: [
            WidgetbookSourceFile(
              Assets.lib.widgets.mutations.mutation.providerSelect,
            ),
            WidgetbookSourceFile(
              Assets.lib.widgets.shared.notifiers.feedbackNotifier,
            ),
          ],
        ),
      ),
    ],
  );
}

WidgetbookComponent mutationGroupComponent() {
  return WidgetbookComponent(name: 'Mutation Group', useCases: [
    WidgetbookUseCase(
      name: 'Mutation Group',
      builder: (context) => CodePreview(
        title: 'Mutation Group - Todo List',
        description: 'Manage independent operations for list items '
            'using keyed mutations.',
        preview: const MutationGroupExample(),
        sourceFiles: [
          WidgetbookSourceFile(
            Assets.lib.widgets.mutations.mutationGroup,
          ),
          WidgetbookSourceFile(
            Assets.lib.widgets.shared.notifiers.todoNotifier,
          ),
        ],
      ),
    ),
  ]);
}
