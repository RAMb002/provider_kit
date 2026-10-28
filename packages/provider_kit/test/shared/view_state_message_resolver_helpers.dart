import 'package:flutter/widgets.dart';
import 'package:provider_kit/provider_kit.dart';

/// Test-only inherited widget that simulates a changing locale.
class TestLocaleInherited extends InheritedWidget {
  const TestLocaleInherited({
    super.key,
    required this.locale,
    required super.child,
  });

  final String locale;

  static String of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<
            TestLocaleInherited>();

    assert(inherited != null, 'TestLocaleInherited not found');

    return inherited!.locale;
  }

  @override
  bool updateShouldNotify(TestLocaleInherited oldWidget) {
    return locale != oldWidget.locale;
  }
}

/// Simulates a message resolver that reads the current locale.
String? testLocaleMessageResolver(
  BuildContext context,
  String message,
) {
  return '${TestLocaleInherited.of(context)}:$message';
}

// Default state widget builders used by tests.

Widget testDefaultInitialStateBuilder(
  BuildContext context,
  bool isSliver,
) => const SizedBox();

Widget testDefaultLoadingStateBuilder(
  BuildContext context,
  LoadingStateDetails details,
  bool isSliver,
) => const SizedBox();

Widget testDefaultEmptyStateBuilder(
  BuildContext context,
  EmptyStateDetails details,
  bool isSliver,
) => const SizedBox();

Widget testDefaultErrorStateBuilder(
  BuildContext context,
  ErrorStateDetails details,
  bool isSliver,
) => const SizedBox();