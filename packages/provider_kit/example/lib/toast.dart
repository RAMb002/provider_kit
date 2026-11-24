import 'package:material_ui/material_ui.dart';

extension UI on BuildContext {
  void showSnackBar(String message, {bool autoHidePrevious = true}) {
    if (autoHidePrevious) ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
