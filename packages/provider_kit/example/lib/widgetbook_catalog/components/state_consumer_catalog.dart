import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/state_consumer/direct_listenable.dart';
import '../../widgets/state_consumer/full_configuration.dart';
import '../../widgets/state_consumer/multi_listenable.dart';
import '../../widgets/state_consumer/multi_provider_lookup.dart';
import '../../widgets/state_consumer/provider_lookup.dart';
import '../shared/code_preview.dart';

WidgetbookComponent stateConsumerComponent() => WidgetbookComponent(
      name: 'StateConsumer',
      useCases: [
        WidgetbookUseCase(
          name: '01 · Direct listenable',
          builder: (_) => CodePreview(
            title: 'StateConsumer · Direct listenable',
            description:
                'Use one directly owned listenable for both rebuilding the UI '
                'and performing side effects.',
            preview: const StateConsumerDirectExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateConsumer.directListenable,
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
            title: 'StateConsumer · Provider lookup (.of)',
            description:
                'Use .of to resolve a Provider-managed notifier for building '
                'and listening.',
            preview: const StateConsumerProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateConsumer.providerLookup,
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
            title: 'StateConsumer · Multiple listenables (.multi)',
            description:
                'Combine locally owned listenables and use their record for '
                'both building and listening.',
            preview: const StateConsumerMultiExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateConsumer.multiListenable,
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
            title: 'StateConsumer · Provider lookups inside .multi',
            description:
                'Resolve several Provider-managed listenables inside .multi '
                'and consume their combined state.',
            preview: const StateConsumerMultiProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateConsumer.multiProviderLookup,
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
            title: 'StateConsumer · Full configuration',
            description:
                'The listener runs only for increases, while the UI rebuilds '
                'when the count enters a new pair. The child is reused.',
            preview: const StateConsumerFullConfigurationExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateConsumer.fullConfiguration,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
            ],
          ),
        ),
      ],
    );
