import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

class ThemeProvider extends StateNotifier<ThemeData> {
  ThemeProvider() : super(ThemeData.light());

  void setDarkTheme() => state = ThemeData.dark();
  void setLightTheme() => state = ThemeData.light();
}

class DarkThemeProvider extends StateNotifier<ThemeData> {
  DarkThemeProvider() : super(ThemeData.dark());

  void setLightTheme() => state = ThemeData.light();
}
