import 'package:flutter/material.dart';

class ScaffoldWithButton extends StatelessWidget {
  const ScaffoldWithButton(
      {super.key,
      required this.title,
      required this.child,
      this.onTap,
      this.icon});

  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: onTap != null
          ? FloatingActionButton(
              onPressed: onTap,
              child: const Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: child,
      ),
    );
  }
}
