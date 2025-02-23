import 'package:flutter/material.dart';

extension UI on BuildContext {
  void showToast(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
