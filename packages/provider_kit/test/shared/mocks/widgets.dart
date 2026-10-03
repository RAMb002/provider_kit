import 'package:flutter/material.dart';

class StateChangeDuringInit extends StatefulWidget {
  const StateChangeDuringInit({super.key, required this.onInit});

  final VoidCallback onInit;

  @override
  State<StateChangeDuringInit> createState() => _StateChangeDuringInitState();
}

class _StateChangeDuringInitState extends State<StateChangeDuringInit> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
