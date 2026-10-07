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

  ({int first, int second}) _previousStates = (first: 0, second: 0);

  @override
  void dispose() {
    _firstNotifier.dispose();
    _secondNotifier.dispose();
    super.dispose();
  }

  String _getChangedProvider(({int first, int second}) states) {
    if (states.first != _previousStates.first) {
      return 'Counter A';
    }

    if (states.second != _previousStates.second) {
      return 'Counter B';
    }

    return 'State';
  }

  void _handleStateChange(({int first, int second}) states) {
    final changedProvider = _getChangedProvider(states);

    _previousStates = states;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showStateChanged(changedProvider);
    });
  }

  Widget _content() {
    ({int first, int second}) providers() => (
          first: _firstNotifier.watch,
          second: _secondNotifier.watch,
        );

    return switch (widget.mode) {
      MultiStateDemoMode.builder => MultiStateBuilder(
          providers: providers,
          builder: (_, states, child) {
            return DemoCard(
              child: _MultiCounterContent(
                firstCount: states.first,
                secondCount: states.second,
                onFirstIncrement: _firstNotifier.increment,
                onSecondIncrement: _secondNotifier.increment,
              ),
            );
          },
        ),
      MultiStateDemoMode.listener => StateListener.multi(
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
      MultiStateDemoMode.consumer => MultiStateConsumer(
          providers: providers,
          listener: (_, states) {
            _handleStateChange(states);
          },
          builder: (_, states, child) {
            return DemoCard(
              showStatus: showStatus,
              statusText: statusText,
              child: _MultiCounterContent(
                firstCount: states.first,
                secondCount: states.second,
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
