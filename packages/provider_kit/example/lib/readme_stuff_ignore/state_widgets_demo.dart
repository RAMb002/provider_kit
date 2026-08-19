import 'package:example/readme_stuff_ignore/demos/mixins/demo_status_controller.dart';
import 'package:example/readme_stuff_ignore/demos/notifier/demo_counter_notifier.dart';
import 'package:example/readme_stuff_ignore/demos/widgets/demo_card.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

enum StateWidgetsDemoMode {
  builder,
  listener,
  consumer,
}

class StateWidgetsDemo extends StatefulWidget {
  const StateWidgetsDemo({
    super.key,
    this.mode = StateWidgetsDemoMode.consumer,
  });

  final StateWidgetsDemoMode mode;

  @override
  State<StateWidgetsDemo> createState() => _StateWidgetsDemoState();
}

class _StateWidgetsDemoState extends State<StateWidgetsDemo>
    with DemoStatusController {
  final DemoCounterNotifier _notifier = DemoCounterNotifier();

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: switch (widget.mode) {
          StateWidgetsDemoMode.builder => StateBuilder<int>(
              provider: _notifier,
              builder: (_, state, __) {
                return DemoCard(
                  child: _SingleCounterContent(
                    value: state,
                    onIncrement: _notifier.increment,
                  ),
                );
              },
            ),
          StateWidgetsDemoMode.listener => _buildListener(),
          StateWidgetsDemoMode.consumer => StateConsumer<int>(
              provider: _notifier,
              listener: (_, state) {
                showStateChanged('State');
              },
              builder: (_, state, __) {
                return DemoCard(
                  showStatus: showStatus,
                  statusText: statusText,
                  child: _SingleCounterContent(
                    value: state,
                    onIncrement: _notifier.increment,
                  ),
                );
              },
            ),
        },
      ),
    );
  }

  Widget _buildListener() {
    return StateListener<int>(
      provider: _notifier,
      listener: (_, __) {
        showStateChanged('State');
      },
      child: DemoCard(
        showStatus: showStatus,
        statusText: statusText,
        child: _SingleCounterContent(
          value: _notifier.state,
          onIncrement: _notifier.increment,
        ),
      ),
    );
  }
}

class _SingleCounterContent extends StatelessWidget {
  const _SingleCounterContent({
    required this.value,
    required this.onIncrement,
  });

  final int value;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Counter',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            '$value',
            key: ValueKey(value),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: onIncrement,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF3D7EFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '+1',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
