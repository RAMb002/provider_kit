import 'package:material_ui/material_ui.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onTap;
  final bool isSliver;

  const EmptyStateWidget({
    required this.message,
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
          const Icon(
            Icons.inbox_outlined,
            size: 36,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            message ?? "No data found",
            style: const TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
