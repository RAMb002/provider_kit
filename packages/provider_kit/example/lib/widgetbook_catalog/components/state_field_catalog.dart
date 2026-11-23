import 'package:example/gen/assets.gen.dart';
import 'package:example/widgetbook_catalog/shared/code_preview.dart';
import 'package:example/widgets/state_field/direct_listenable.dart';
import 'package:example/widgets/state_field/provider_select.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent stateFieldComponent() {
  return WidgetbookComponent(
    name: 'StateField',
    isInitiallyExpanded: false,
    useCases: [
      WidgetbookUseCase(
        name: 'Direct Listenable',
        builder: (context) => CodePreview(
          title: 'StateField - Direct Listenable',
          description: 'Pass an independently owned StateField directly '
              'to State Widgets.',
          preview: const StateFieldDirectExample(),
          sourceFiles: [
            WidgetbookSourceFile(
              Assets.lib.widgets.stateField.directListenable,
            ),
          ],
        ),
      ),
      WidgetbookUseCase(
        name: 'Provider Integration',
        builder: (context) => CodePreview(
          title: 'StateField - Provider Integration',
          description: 'Observe a StateField owned by a ChangeNotifier '
              'using .select on State Widgets.',
          preview: const StateFieldSelectExample(),
          sourceFiles: [
            WidgetbookSourceFile(
              Assets.lib.widgets.stateField.providerSelect,
            ),
            WidgetbookSourceFile(
              Assets.lib.widgets.shared.notifiers.counterFieldNotifier,
            ),
          ],
        ),
      ),
    ],
  );
}
