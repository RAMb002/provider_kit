import 'package:flutter/material.dart';

class LoadingStateWidget extends StatelessWidget {
  final bool isSliver;

  const LoadingStateWidget({
    this.isSliver = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return isSliver
        ? SliverFillRemaining(
            child: _loadingWidget(),
          )
        : _loadingWidget();
  }

  Center _loadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }
}
