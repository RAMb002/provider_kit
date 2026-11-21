import 'package:widgetbook/widgetbook.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/nested_state_listener/nested_state_listener.dart';
import '../../widgets/watch_builder/watch_builder.dart';
import '../shared/code_preview.dart';

WidgetbookComponent watchBuilderComponent() => WidgetbookComponent(
      name: 'WatchBuilder',
      useCases: [
        WidgetbookUseCase(
          name: 'Watch multiple dependencies',
          builder: (_) => CodePreview(
            title: 'WatchBuilder · Multiple dependencies',
            description:
                'Read one or more listenables with .watch inside the builder. '
                'The widget tracks those dependencies and rebuilds when they change.',
            preview: const WatchBuilderExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.watchBuilder.watchBuilder,
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
      ],
    );

WidgetbookComponent nestedStateListenerComponent() => WidgetbookComponent(
      name: 'NestedStateListener',
      useCases: [
        WidgetbookUseCase(
          name: 'Combine independent listeners',
          builder: (_) => CodePreview(
            title: 'NestedStateListener · Independent listeners',
            description:
                'Group multiple StateListener widgets under one parent without '
                'manually nesting their child widgets.',
            preview: const NestedStateListenerExample(),
            sourceFiles: [
              WidgetbookSourceFile(
                Assets.lib.widgets.nestedStateListener.nestedStateListener,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.counterNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.stepNotifier,
              ),
              WidgetbookSourceFile(
                Assets.lib.widgets.shared.notifiers.directMovieNotifier,
              ),
            ],
          ),
        ),
      ],
    );
