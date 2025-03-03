import 'package:flutter/material.dart';

class ScaffoldWithMultiButton extends StatelessWidget {
  const ScaffoldWithMultiButton({
    super.key,
    required this.title,
    required this.child,
    required this.onTap1,
    required this.onTap2,
    required this.onTap3,
  });

  final String title;
  final Widget child;
  final VoidCallback onTap1;
  final VoidCallback onTap2;
  final VoidCallback onTap3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: '1',
            onPressed: onTap1,
            child: const Icon(Icons.looks_one),
          ),
          const SizedBox(
            height: 5,
          ),
          FloatingActionButton(
            heroTag: '2',
            onPressed: onTap2,
            child: const Icon(Icons.looks_two),
          ),
          const SizedBox(
            height: 5,
          ),
          FloatingActionButton(
            heroTag: '3',
            onPressed: onTap3,
            child: const Icon(Icons.timer_3_sharp),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: child,
      ),
    );
  }
}
