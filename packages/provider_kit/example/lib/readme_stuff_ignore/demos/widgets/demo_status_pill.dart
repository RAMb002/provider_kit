import 'package:flutter/material.dart';

class DemoStatusPill extends StatelessWidget {
  const DemoStatusPill({
    super.key,
    required this.visible,
    required this.text,
  });

  final bool visible;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: visible && text != null
          ? Container(
              key: ValueKey(text),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Color(0xFF238B55),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    text!,
                    style: const TextStyle(
                      color: Color(0xFF238B55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(
              key: ValueKey('empty_status'),
              height: 29,
            ),
    );
  }
}
