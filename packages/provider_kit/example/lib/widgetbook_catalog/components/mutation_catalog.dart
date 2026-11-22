import 'package:example/example_kits/mutations/mutation.dart';
import 'package:example/gen/assets.gen.dart';
import 'package:example/widgetbook_catalog/shared/code_preview.dart';
import 'package:example/widgets/mutations/mutation/mutation_direct_listenable.dart';
import 'package:widgetbook/widgetbook.dart';

// Import CodePreview and WidgetbookSourceFile from your existing shared file.

WidgetbookComponent mutationComponent() {
  return WidgetbookComponent(
    name: 'Mutation',
    useCases: [
      WidgetbookUseCase(
        name: 'Direct Listenable',
        builder: (context) => CodePreview(
          title: 'Mutation - Direct Listenable',
          description:
              'Pass a locally owned Mutation directly to StateBuilder.',
          preview: const MutationDirectExample(),
          sourceFiles: [
            WidgetbookSourceFile(
              Assets.lib.widgets.mutations.mutation.mutationDirectListenable,
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
              'selector.',
          preview: const MutationProviderExample(),
          sourceFiles: [
            WidgetbookSourceFile(
              Assets.lib.widgets.mutations.mutation.providerLookup,
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
