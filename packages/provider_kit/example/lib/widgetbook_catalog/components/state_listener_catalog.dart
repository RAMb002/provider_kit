import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/state_listener/direct_listenable.dart';
import '../../widgets/state_listener/full_configuration.dart';
import '../../widgets/state_listener/multi_listenable.dart';
import '../../widgets/state_listener/multi_provider_lookup.dart';
import '../../widgets/state_listener/provider_lookup.dart';
import '../shared/code_preview.dart';

WidgetbookComponent stateListenerComponent() => WidgetbookComponent(
      name: 'StateListener',
      isInitiallyExpanded: false,
      useCases: [
        WidgetbookUseCase(
          name: '01 · Direct listenable',
          builder: (_) => CodePreview(
            title: 'StateListener · Direct listenable',
            description:
                'Listen to a locally owned listenable and show a SnackBar '
                'when its state changes. The listener does not rebuild its child.',
            preview: const StateListenerDirectExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateListener.directListenable,
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
            title: 'StateListener · Provider lookup (.of)',
            description:
                'Resolve a Provider-managed notifier with .of and react '
                'to its state changes.',
            preview: const StateListenerProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateListener.providerLookup,
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
            title: 'StateListener · Multiple listenables (.multi)',
            description:
                'Listen to multiple locally owned listenables and receive '
                'their combined record in one callback.',
            preview: const StateListenerMultiExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateListener.multiListenable,
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
            title: 'StateListener · Provider lookups inside .multi',
            description: 'Resolve multiple Provider-managed listenables inside '
                'the .multi callback.',
            preview: const StateListenerMultiProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateListener.multiProviderLookup,
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
            title: 'StateListener · Full configuration',
            description: 'Explore listenWhen and callListenerOnInit, alongside '
                'the side-effect callback and child.',
            preview: const StateListenerFullConfigurationExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.stateListener.fullConfiguration,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
            ],
          ),
        ),
      ],
    );
