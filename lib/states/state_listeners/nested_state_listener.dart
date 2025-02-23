import 'package:nested/nested.dart';

class NestedStateListener extends Nested {
  NestedStateListener({
    super.key,
    required List<SingleChildWidget> listeneres,
    required super.child,
  }) : super(
          children: listeneres,
        );
}
