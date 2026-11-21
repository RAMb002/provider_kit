import 'package:example/widgetbook_catalog/components/mutation_catalog.dart';
import 'package:widgetbook/widgetbook.dart';

final WidgetbookCategory mutationsDirectory = WidgetbookCategory(
  name: 'Mutations',
  children: [
    mutationComponent(),
    // mutationGroupComponent(),
  ],
);