import 'package:flutter/material.dart';

class InitialStateWidget extends StatelessWidget {
  const InitialStateWidget({
    super.key,
    this.isSliver = false,
  });
  final bool isSliver;

  @override
  Widget build(BuildContext context) {
    return isSliver
        ? SliverFillRemaining(
            child: _initialWidget(),
          )
        : _initialWidget();
  }

  Center _initialWidget() {
    return const Center(
      child: Text(
        "Process starting",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
