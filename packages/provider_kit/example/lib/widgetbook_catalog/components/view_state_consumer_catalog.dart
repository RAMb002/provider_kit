import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/view_state_consumer/direct_listenable.dart';
import '../../widgets/view_state_consumer/full_configuration.dart';
import '../../widgets/view_state_consumer/multi_listenable.dart';
import '../../widgets/view_state_consumer/multi_provider_lookup.dart';
import '../../widgets/view_state_consumer/provider_lookup.dart';
import '../shared/code_preview.dart';

WidgetbookComponent viewStateConsumerComponent() => WidgetbookComponent(
      name: 'ViewStateConsumer',
      useCases: [
        WidgetbookUseCase(
          name: '01 · Direct listenable',
          builder: (_) => CodePreview(
            title: 'ViewStateConsumer · Direct listenable',
            description:
                'Use one locally owned notifier to build data UI and perform side '
                'effects.',
            preview: const ViewStateConsumerDirectExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateConsumer.directListenable,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.moviesNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.demoMain,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '02 · Provider lookup (.of)',
          builder: (_) => CodePreview(
            title: 'ViewStateConsumer · Provider lookup (.of)',
            description:
                'Resolve a Provider-managed ViewState notifier with .of for both '
                'building and listening.',
            preview: const ViewStateConsumerProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateConsumer.providerLookup,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.moviesNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.demoMain,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '03 · Multiple listenables (.multi)',
          builder: (_) => CodePreview(
            title: 'ViewStateConsumer · Multiple listenables (.multi)',
            description:
                'Combine multiple locally owned listenables for state-specific '
                'building and listening.',
            preview: const ViewStateConsumerMultiExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateConsumer.multiListenable,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.moviesNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.recommendationsNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.demoMain,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '04 · Provider lookups inside .multi',
          builder: (_) => CodePreview(
            title: 'ViewStateConsumer · Provider lookups inside .multi',
            description:
                'Resolve multiple Provider-managed notifiers inside the .multi '
                'listenables callback.',
            preview: const ViewStateConsumerMultiProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateConsumer.multiProviderLookup,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.moviesNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.recommendationsNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.demoMain,
              ),
            ],
          ),
        ),
        WidgetbookUseCase(
          name: '05 · Full configuration',
          builder: (_) => CodePreview(
            title: 'ViewStateConsumer · Full configuration',
            description:
                'Explore all state-specific builders and listeners, filtering, sliver '
                'configuration and child.',
            preview: const ViewStateConsumerFullConfigurationExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateConsumer.fullConfiguration,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.moviesNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.demoMain,
              ),
            ],
          ),
        ),
      ],
    );
