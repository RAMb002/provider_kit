import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String? text;
  final VoidCallback? onTap;
  final bool isSliver;

  const ErrorStateWidget({
    required this.text,
    required this.onTap,
    this.isSliver = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return isSliver
        ? SliverFillRemaining(
            child: _errorWidget(),
          )
        : _errorWidget();
  }

  Center _errorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text ?? "Something went wrong",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
