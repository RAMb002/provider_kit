import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/state_builder/direct_listenable.dart';
import '../../widgets/state_builder/full_configuration.dart';
import '../../widgets/state_builder/multi_listenable.dart';
import '../../widgets/state_builder/multi_provider_lookup.dart';
import '../../widgets/state_builder/provider_lookup.dart';
import '../shared/code_preview.dart';

WidgetbookComponent stateBuilderComponent() => WidgetbookComponent(
      name: 'StateBuilder',
      useCases: [
        WidgetbookUseCase(
          name: '01 · Direct listenable',
          builder: (_) => CodePreview(
            title: 'StateBuilder · Direct listenable',
            description:
                'Pass a stable listenable directly when the widget owns it. '
                'The example disposes its notifier in dispose().',
            preview: const StateBuilderDirectExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateBuilder.directListenable,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '02 · Provider lookup (.of)',
          builder: (_) => CodePreview(
            title: 'StateBuilder · Provider lookup (.of)',
            description: 'Resolve a Provider-managed notifier with .of. '
                'Provider owns and disposes the notifier.',
            preview: const StateBuilderProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateBuilder.providerLookup,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '03 · Multiple listenables (.multi)',
          builder: (_) => CodePreview(
            title: 'StateBuilder · Multiple listenables (.multi)',
            description:
                'Combine independent, locally owned listenables into one '
                'type-safe record with .multi.',
            preview: const StateBuilderMultiExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateBuilder.multiListenable,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.stepNotifier,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '04 · Provider lookups inside .multi',
          builder: (_) => CodePreview(
            title: 'StateBuilder · Provider lookups inside .multi',
            description:
                'Resolve and combine multiple Provider-managed notifiers '
                'inside the .multi listenables callback.',
            preview: const StateBuilderMultiProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateBuilder.multiProviderLookup,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.stepNotifier,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '05 · Full configuration',
          builder: (_) => CodePreview(
            title: 'StateBuilder · Full configuration',
            description:
                'The rebuildWhen filter updates the displayed count only when '
                'it enters a new pair. The child is passed separately.',
            preview: const StateBuilderFullConfigurationExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateBuilder.fullConfiguration,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
            ],
          ),
        ),
      ],
    );
