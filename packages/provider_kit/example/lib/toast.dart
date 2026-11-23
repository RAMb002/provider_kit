import 'package:flutter/material.dart';

extension UI on BuildContext {
  void showSnackBar(String message, {bool autoHidePrevious = true}) {
    if (autoHidePrevious) ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
