import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/view_state_listener/direct_listenable.dart';
import '../../widgets/view_state_listener/full_configuration.dart';
import '../../widgets/view_state_listener/multi_listenable.dart';
import '../../widgets/view_state_listener/multi_provider_lookup.dart';
import '../../widgets/view_state_listener/provider_lookup.dart';
import '../shared/code_preview.dart';

WidgetbookComponent viewStateListenerComponent() => WidgetbookComponent(
      name: 'ViewStateListener',
      isInitiallyExpanded: false,
      useCases: [
        WidgetbookUseCase(
          name: '01 · Direct listenable',
          builder: (_) => CodePreview(
            title: 'ViewStateListener · Direct listenable',
            description:
                'Listen to a locally owned ViewState notifier and show a SnackBar '
                'when data becomes available.',
            preview: const ViewStateListenerDirectExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateListener.directListenable,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.directMovieNotifier,
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
            title: 'ViewStateListener · Provider lookup (.of)',
            description:
                'Resolve a Provider-managed ViewState notifier with .of. Provider '
                'owns and disposes the notifier.',
            preview: const ViewStateListenerProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateListener.providerLookup,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.directMovieNotifier,
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
            title: 'ViewStateListener · Multiple listenables (.multi)',
            description:
                'Listen to multiple locally owned ViewState notifiers through one '
                'combined state.',
            preview: const ViewStateListenerMultiExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateListener.multiListenable,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.directMovieNotifier,
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
            title: 'ViewStateListener · Provider lookups inside .multi',
            description:
                'Resolve multiple Provider-managed notifiers inside the .multi '
                'listenables callback.',
            preview: const ViewStateListenerMultiProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateListener.multiProviderLookup,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.directMovieNotifier,
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
            title: 'ViewStateListener · Full configuration',
            description:
                'Explore state-specific listener callbacks, listenWhen, '
                'callListenerOnInit and child.',
            preview: const ViewStateListenerFullConfigurationExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateListener.fullConfiguration,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.directMovieNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.demoMain,
              ),
            ],
          ),
        ),
      ],
    );
