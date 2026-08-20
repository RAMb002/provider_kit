import 'package:example/readme_stuff_ignore/demos/mixins/demo_status_controller.dart';
import 'package:example/readme_stuff_ignore/demos/notifier/demo_counter_notifier.dart';
import 'package:example/readme_stuff_ignore/demos/widgets/demo_card.dart';
import 'package:example/readme_stuff_ignore/demos/widgets/demo_counter_item.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

enum MultiStateDemoMode {
  builder,
  listener,
  consumer,
}

class MultiStateWidgetsDemo extends StatefulWidget {
  const MultiStateWidgetsDemo({
    super.key,
    this.mode = MultiStateDemoMode.consumer,
  });

  final MultiStateDemoMode mode;

  @override
  State<MultiStateWidgetsDemo> createState() => _MultiStateWidgetsDemoState();
}

class _MultiStateWidgetsDemoState extends State<MultiStateWidgetsDemo>
    with DemoStatusController {
  final DemoCounterNotifier _firstNotifier = DemoCounterNotifier();
  final DemoCounterNotifier _secondNotifier = DemoCounterNotifier();

  List<int> _previousStates = [0, 0];

  @override
  void dispose() {
    _firstNotifier.dispose();
    _secondNotifier.dispose();
    super.dispose();
  }

  String _getChangedProvider(List<int> states) {
    if (states[0] != _previousStates[0]) {
      return 'Counter A';
    }

    if (states[1] != _previousStates[1]) {
      return 'Counter B';
    }

    return 'State';
  }

  void _handleStateChange(List<int> states) {
    final changedProvider = _getChangedProvider(states);

    _previousStates = List<int>.from(states);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showStateChanged(changedProvider);
    });
  }

  Widget _content() {
    final providers = <DemoCounterNotifier>[
      _firstNotifier,
      _secondNotifier,
    ];

    return switch (widget.mode) {
      MultiStateDemoMode.builder => MultiStateBuilder<int>(
          providers: providers,
          builder: (_, states, __) {
            return DemoCard(
              child: _MultiCounterContent(
                firstCount: states[0],
                secondCount: states[1],
                onFirstIncrement: _firstNotifier.increment,
                onSecondIncrement: _secondNotifier.increment,
              ),
            );
          },
        ),
      MultiStateDemoMode.listener => MultiStateListener<int>(
          providers: providers,
          listener: (_, states) {
            _handleStateChange(states);
          },
          child: DemoCard(
            showStatus: showStatus,
            statusText: statusText,
            child: _MultiCounterContent(
              firstCount: _firstNotifier.state,
              secondCount: _secondNotifier.state,
              onFirstIncrement: _firstNotifier.increment,
              onSecondIncrement: _secondNotifier.increment,
            ),
          ),
        ),
      MultiStateDemoMode.consumer => MultiStateConsumer<int>(
          providers: providers,
          listener: (_, states) {
            _handleStateChange(states);
          },
          builder: (_, states, __) {
            return DemoCard(
              showStatus: showStatus,
              statusText: statusText,
              child: _MultiCounterContent(
                firstCount: states[0],
                secondCount: states[1],
                onFirstIncrement: _firstNotifier.increment,
                onSecondIncrement: _secondNotifier.increment,
              ),
            );
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: _content(),
      ),
    );
  }
}

class _MultiCounterContent extends StatelessWidget {
  const _MultiCounterContent({
    required this.firstCount,
    required this.secondCount,
    required this.onFirstIncrement,
    required this.onSecondIncrement,
  });

  final int firstCount;
  final int secondCount;
  final VoidCallback onFirstIncrement;
  final VoidCallback onSecondIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Multiple States',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: DemoCounterItem(
                label: 'Counter A',
                value: firstCount,
                onIncrement: onFirstIncrement,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DemoCounterItem(
                label: 'Counter B',
                value: secondCount,
                onIncrement: onSecondIncrement,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
