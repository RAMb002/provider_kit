import 'package:material_ui/material_ui.dart';

class LoadingStateWidget extends StatelessWidget {
  final bool isSliver;
  final String? message;

  const LoadingStateWidget({
    this.isSliver = false,
    this.message,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(
            height: 10,
          ),
          Text(
            message ?? "Loading",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
