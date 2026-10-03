import 'package:flutter/material.dart';

class ScaffoldWithMultiButton extends StatelessWidget {
  const ScaffoldWithMultiButton({
    super.key,
    required this.title,
    required this.child,
    required this.onTap1,
    required this.onTap2,
    required this.onTap3,
    this.label1,
    this.label2,
    this.label3,
    this.icon1,
    this.icon2,
    this.icon3,
  });

  final String title;
  final Widget child;

  final VoidCallback onTap1;
  final VoidCallback onTap2;
  final VoidCallback onTap3;

  final String? label1;
  final String? label2;
  final String? label3;

  final IconData? icon1;
  final IconData? icon2;
  final IconData? icon3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: '1',
            onPressed: onTap1,
            icon: Icon(icon1 ?? Icons.looks_one),
            label: Text(label1 ?? '1'),
          ),
          const SizedBox(height: 5),
          FloatingActionButton.extended(
            heroTag: '2',
            onPressed: onTap2,
            icon: Icon(icon2 ?? Icons.looks_two),
            label: Text(label2 ?? '2'),
          ),
          const SizedBox(height: 5),
          FloatingActionButton.extended(
            heroTag: '3',
            onPressed: onTap3,
            icon: Icon(icon3 ?? Icons.timer_3_sharp),
            label: Text(label3 ?? '3'),
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
