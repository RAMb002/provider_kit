import 'package:example/readme_stuff_ignore/demos/notifier/demo_multi_view_state_notifier.dart';
import 'package:example/readme_stuff_ignore/demos/widgets/demo_card.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// ---------------------------------------------------------------------------
/// Demo notifier
/// ---------------------------------------------------------------------------

/// ---------------------------------------------------------------------------
/// Before / After demo
/// ---------------------------------------------------------------------------

class MultiViewStateWidgetsDemo extends StatefulWidget {
  const MultiViewStateWidgetsDemo({
    super.key,
  });

  @override
  State<MultiViewStateWidgetsDemo> createState() =>
      _MultiViewStateWidgetsDemoState();
}

class _MultiViewStateWidgetsDemoState extends State<MultiViewStateWidgetsDemo> {
  late final DemoMultiViewStateNotifier _providerOne;
  late final DemoMultiViewStateNotifier _providerTwo;

  @override
  void initState() {
    super.initState();

    _providerOne = DemoMultiViewStateNotifier(
      data: 'Flutter',
    );

    _providerTwo = DemoMultiViewStateNotifier(
      data: 'ProviderKit',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _providerOne.load();
      _providerTwo.load(3000);
    });
  }

  @override
  void dispose() {
    _providerOne.dispose();
    _providerTwo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  _buildTitle('Without MultiViewState'),
                  const SizedBox(
                    height: 10,
                  ),
                  _buildBefore(),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_right_alt),
              ),
              Column(
                children: [
                  _buildTitle('With MultiViewState'),
                  const SizedBox(
                    height: 10,
                  ),
                  _buildAfter(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBefore() {
    return SizedBox(
      height: 166,
      child: DemoCard(
        cardWidth: 270,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildIndividualViewState(_providerOne),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIndividualViewState(_providerTwo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualViewState(
    DemoMultiViewStateNotifier provider,
  ) {
    return Center(
      child: ViewStateBuilder<String>(
        provider: provider,
        loadingBuilder: (_, __, ___) => const DemoLoadingContent(),
        dataBuilder: (data) => DemoDataContent(
          data: data,
        ),
      ),
    );
  }

  Widget _buildAfter() {
    return SizedBox(
      height: 166,
      child: DemoCard(
        cardWidth: 270,
        child: MultiViewStateBuilder<String>(
          providers: [
            _providerOne,
            _providerTwo,
          ],
          loadingBuilder: (_, __, ___) => const DemoLoadingContent(),
          dataBuilder: (states) {
            final data = states.map((state) => state.data).join(' • ');

            return DemoDataContent(
              data: data,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class DemoLoadingContent extends StatelessWidget {
  const DemoLoadingContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF3D7EFF),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Loading...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoDataContent extends StatelessWidget {
  const DemoDataContent({
    super.key,
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 28,
          color: Color(0xFF238B55),
        ),
        const SizedBox(height: 8),
        const Text(
          'Data',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE7E9EE),
            ),
          ),
          child: Text(
            data,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
