// Explore the interactive ProviderKit Widgetbook:
// https://RAMb002.github.io/provider_kit/widgetbook/

import 'package:example/widgetbook_catalog/components/state_field_catalog.dart';
import 'package:example/widgetbook_catalog/mutation_directory.dart';
import 'package:example/widgets/shared/repositories/movies_repository.dart';
import 'package:example/widgets/shared/view_state_defaults.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:widgetbook/widgetbook.dart';

import 'widgetbook_catalog/widgets_directory.dart';

void main() {
  ProviderKit.configure(
    observer: DebugNotifierObserver(),
    errorInfoMapper: (error, stackTrace) {
      if (error is MoviesException) {
        return const ErrorInfo(
          message: 'Failed to load movies.',
          code: 'movies_load_failed',
        );
      }
      return ErrorInfo(
        message: error.toString(),
      );
    },
  );
  runApp(const ProviderKitWidgetbook());
}

class ProviderKitWidgetbook extends StatelessWidget {
  const ProviderKitWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return ExampleViewStateDefaults(
      child: Widgetbook.material(
        directories: [
          widgetsDirectory,
          mutationsDirectory,
          stateFieldComponent(),
        ],
        initialRoute:
            "?path=widgets/state-widgets/statebuilder/01-·-direct-listenable",
        appBuilder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _darkTheme,
            darkTheme: _darkTheme,
            themeMode: ThemeMode.dark,
            builder: (context, child) {
              // Temporary bridge for Widgetbook's legacy Material widgets.
              // ignore: deprecated_member_use
              return MaterialUiCompatibilityBridge(
                child: child!,
              );
            },
            home: Material(
              color: _darkTheme.scaffoldBackgroundColor,
              child: child,
            ),
          );
        },
      ),
    );
  }

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9AA8FF),
      brightness: Brightness.dark,
    ),
  );
}
