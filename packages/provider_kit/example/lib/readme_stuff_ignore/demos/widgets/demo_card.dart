import 'package:example/readme_stuff_ignore/demos/widgets/demo_status_pill.dart';
import 'package:flutter/material.dart';

class DemoCard extends StatelessWidget {
  const DemoCard({
    super.key,
    required this.child,
    this.statusText,
    this.showStatus = false,
    this.cardWidth = 340,
  });

  final Widget child;
  final String? statusText;
  final bool showStatus;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7E9EE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 16),
          if (showStatus || statusText != null)
            DemoStatusPill(
              visible: showStatus,
              text: statusText,
            ),
        ],
      ),
    );
  }
}
