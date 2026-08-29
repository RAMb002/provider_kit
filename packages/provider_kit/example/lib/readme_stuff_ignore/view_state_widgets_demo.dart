import 'package:example/readme_stuff_ignore/demos/mixins/demo_status_controller.dart';
import 'package:example/readme_stuff_ignore/demos/notifier/demo_view_state_notifier.dart';
import 'package:example/readme_stuff_ignore/demos/widgets/demo_card.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

enum ViewStateWidgetsDemoMode {
  builder,
  listener,
  consumer,
}

class ViewStateWidgetsDemo extends StatefulWidget {
  const ViewStateWidgetsDemo({
    super.key,
    this.mode = ViewStateWidgetsDemoMode.builder,
  });

  final ViewStateWidgetsDemoMode mode;

  @override
  State<ViewStateWidgetsDemo> createState() => _ViewStateWidgetsDemoState();
}

class _ViewStateWidgetsDemoState extends State<ViewStateWidgetsDemo>
    with DemoStatusController {
  final DemoViewStateNotifier _notifier = DemoViewStateNotifier();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.startInitialLoad();
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Widget _contentForState(
    ViewState<String> state,
  ) {
    return switch (state) {
      InitialState<String>() => const DemoViewStateContent(
          message: 'Starting...',
          icon: Icons.circle_outlined,
          iconColor: Color(0xFF6B7280),
          actionLabel: '',
          onAction: null,
        ),
      LoadingState<String>() => const CircularProgressIndicator(
          color: Colors.black,
        ),
      EmptyState<String>() => DemoViewStateContent(
          message: state.message ?? 'No data found',
          icon: Icons.inbox_outlined,
          iconColor: Colors.blue,
          actionLabel: 'Refresh',
          onAction: _notifier.refresh,
        ),
      ErrorState<String>() => DemoViewStateContent(
          message: state.message,
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE05252),
          actionLabel: 'Retry',
          buttonColor: Colors.red,
          onAction: state.onRetry ?? _notifier.retry,
        ),
      DataState<String>() => const DemoViewStateDataContent(
          onAction: null,
        ),
    };
  }

  Widget _buildBuilder() {
    return ViewStateBuilder<String>(
      provider: _notifier,
      initialBuilder: (_) => _contentForState(
        const InitialState<String>(),
      ),
      loadingBuilder: (message, progress, _) => _contentForState(
        LoadingState<String>(message, progress),
      ),
      emptyBuilder: (message, _) => _contentForState(
        EmptyState<String>(message),
      ),
      errorBuilder: (errorInfo, error, stackTrace, onRetry, _) =>
          _contentForState(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: onRetry,
        ),
      ),
      dataBuilder: (data) => _contentForState(
        DataState<String>(data),
      ),
    );
  }

  Widget _buildListener() {
    return ViewStateListener<String>(
      provider: _notifier,
      initialStateListener: () {
        showStateChanged('Initial');
      },
      loadingStateListener: (message, progress) {
        showStateChanged('Loading');
      },
      emptyStateListener: (message) {
        showStateChanged('Empty');
      },
      errorStateListener: (message, onRetry, exception, stackTrace) {
        showStateChanged('Error');
      },
      dataStateListener: (data) {
        showStateChanged('Data');
      },
      child: DemoCard(
        showStatus: showStatus,
        statusText: statusText,
        child: _ListenerContent(
          onRetry: _notifier.retry,
          onRefresh: _notifier.refresh,
        ),
      ),
    );
  }

  Widget _buildConsumer() {
    return ViewStateConsumer<String>(
      provider: _notifier,
      initialBuilder: (_) => _contentForState(
        const InitialState<String>(),
      ),
      loadingBuilder: (message, progress, _) => _contentForState(
        LoadingState<String>(message, progress),
      ),
      emptyBuilder: (message, _) => _contentForState(
        EmptyState<String>(message),
      ),
      errorBuilder: (errorInfo, error, stackTrace, onRetry, _) =>
          _contentForState(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: onRetry,
        ),
      ),
      dataBuilder: (data) => _contentForState(
        DataState<String>(data),
      ),
      initialStateListener: () {
        showStateChanged('Initial');
      },
      loadingStateListener: (message, progress) {
        showStateChanged('Loading');
      },
      emptyStateListener: (message) {
        showStateChanged('Empty');
      },
      errorStateListener: (message, onRetry, exception, stackTrace) {
        showStateChanged('Error');
      },
      dataStateListener: (data) {
        showStateChanged('Data');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: switch (widget.mode) {
          ViewStateWidgetsDemoMode.builder => _buildBuilder(),
          ViewStateWidgetsDemoMode.listener => _buildListener(),
          ViewStateWidgetsDemoMode.consumer => _buildConsumer(),
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Listener-only content
/// ---------------------------------------------------------------------------

class _ListenerContent extends StatelessWidget {
  const _ListenerContent({
    required this.onRetry,
    required this.onRefresh,
  });

  final VoidCallback onRetry;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          size: 30,
          color: Color(0xFF3D7EFF),
        ),
        const SizedBox(height: 10),
        const Text(
          'Listening',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'React to ViewState changes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF3D7EFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFF0F4FF),
                foregroundColor: const Color(0xFF3D7EFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }
}

class DemoViewStateDataContent extends StatelessWidget {
  const DemoViewStateDataContent({
    super.key,
    required this.onAction,
  });

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    const items = [
      'Flutter',
      'ProviderKit',
      'State Management',
      'Mutations',
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 30,
                color: Color(0xFF238B55),
              ),
              SizedBox(width: 5),
              Text(
                'Data Loaded',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map(
            (entry) {
              final index = entry.key + 1;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE7E9EE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Color(0xFF238B55),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DemoViewStateContent extends StatelessWidget {
  const DemoViewStateContent({
    super.key,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.onAction,
    this.buttonColor,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color? buttonColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 30,
            color: iconColor,
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: buttonColor ?? const Color(0xFF3D7EFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
