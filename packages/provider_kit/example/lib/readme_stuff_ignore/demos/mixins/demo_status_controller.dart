import 'dart:async';
import 'package:flutter/material.dart';

mixin DemoStatusController<T extends StatefulWidget> on State<T> {
  Timer? _statusTimer;

  bool showStatus = false;
  String? statusText;

  void showStateChanged(String name) {
    _statusTimer?.cancel();

    setState(() {
      showStatus = true;
      statusText = '$name changed';
    });

    _statusTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      setState(() {
        showStatus = false;
      });
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}
