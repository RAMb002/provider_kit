import 'package:example/widgetbook_catalog/components/view_state_builder_catalog.dart';
import 'package:example/widgetbook_catalog/components/view_state_consumer_catalog.dart';
import 'package:example/widgetbook_catalog/components/view_state_listener_catalog.dart';
import 'package:widgetbook/widgetbook.dart';

import 'components/other_widgets_catalog.dart';
import 'components/state_builder_catalog.dart';
import 'components/state_consumer_catalog.dart';
import 'components/state_listener_catalog.dart';

final WidgetbookCategory widgetsDirectory = WidgetbookCategory(
  name: 'Widgets',
  children: [
    WidgetbookCategory(
      name: 'State Widgets',
      children: [
        stateBuilderComponent(),
        stateListenerComponent(),
        stateConsumerComponent(),
      ],
    ),
    WidgetbookCategory(
      name: 'View State Widgets',
      children: [
        viewStateBuilderComponent(),
        viewStateListenerComponent(),
        viewStateConsumerComponent(),
      ],
    ),
    nestedStateListenerComponent(),
    watchBuilderComponent(),
  ],
);
