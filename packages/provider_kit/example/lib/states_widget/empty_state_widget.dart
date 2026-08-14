import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isSliver;

  const EmptyStateWidget({
    this.isSliver = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return isSliver
        ? SliverFillRemaining(
            child: _emptyWidget(),
          )
        : _emptyWidget();
  }

  Center _emptyWidget() {
    return const Center(
      child: Text(
        "No data found",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
