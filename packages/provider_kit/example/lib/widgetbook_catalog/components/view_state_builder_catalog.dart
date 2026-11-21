import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/view_state_builder/direct_listenable.dart';
import '../../widgets/view_state_builder/full_configuration.dart';
import '../../widgets/view_state_builder/multi_listenable.dart';
import '../../widgets/view_state_builder/multi_provider_lookup.dart';
import '../../widgets/view_state_builder/provider_lookup.dart';
import '../shared/code_preview.dart';

WidgetbookComponent viewStateBuilderComponent() => WidgetbookComponent(
      name: 'ViewStateBuilder',
      useCases: [
        WidgetbookUseCase(
          name: '01 · Direct listenable',
          builder: (_) => CodePreview(
            title: 'ViewStateBuilder · Direct listenable',
            description:
                'Pass a locally owned ViewState notifier directly. The example owns '
                'and disposes the notifier.',
            preview: const ViewStateBuilderDirectExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateBuilder.directListenable,
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
            title: 'ViewStateBuilder · Provider lookup (.of)',
            description:
                'Resolve a Provider-managed ViewState notifier with .of. Provider '
                'owns and disposes the notifier.',
            preview: const ViewStateBuilderProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateBuilder.directListenable,
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
            title: 'ViewStateBuilder · Multiple listenables (.multi)',
            description:
                'Combine multiple locally owned ViewState listenables into one typed '
                'record with .multi.',
            preview: const ViewStateBuilderMultiExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateBuilder.multiListenable,
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
            title: 'ViewStateBuilder · Provider lookups inside .multi',
            description:
                'Resolve multiple Provider-managed notifiers inside the .multi '
                'listenables callback.',
            preview: const ViewStateBuilderMultiProviderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateBuilder.multiProviderLookup,
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
            title: 'ViewStateBuilder · Full configuration',
            description:
                'Explore state-specific builders, filtering, sliver configuration and '
                'the optional child.',
            preview: const ViewStateBuilderFullConfigurationExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.viewStateBuilder.fullConfiguration,
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
