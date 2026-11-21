import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates independent keyed mutations for list items.
class MutationGroupExample extends StatefulWidget {
  const MutationGroupExample({super.key});

  @override
  State<MutationGroupExample> createState() => _MutationGroupExampleState();
}

class _MutationGroupExampleState extends State<MutationGroupExample> {
  late final _archiveGroup = MutationGroup<void>(
    concurrency: MutationConcurrency.ignoreIfBusy,
    keepAliveStates: {
      KeepAliveState.success,
      KeepAliveState.error,
    },
  );

  final _attempts = <String, int>{};

  static const _tasks = [
    ('task_1', 'Prepare release notes'),
    ('task_2', 'Review pull requests'),
    ('task_3', 'Update documentation'),
  ];

  @override
  void dispose() {
    _archiveGroup.dispose();
    super.dispose();
  }

  Future<void> _archiveTask(String id) async {
    await _archiveGroup(id).run(() async {
      await Future.delayed(const Duration(seconds: 2));

      final attempt = (_attempts[id] ?? 0) + 1;
      _attempts[id] = attempt;

      // Demonstrate an error followed by a successful retry.
      if (id == 'task_2' && attempt == 1) {
        throw StateError('Unable to archive this task.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final task in _tasks)
            StateBuilder<MutationState<void>>(
              listenable: _archiveGroup(task.$1),
              builder: (context, state, child) {
                final theme = Theme.of(context);

                String? subtitle;

                Widget action;

                if (state is MutationLoading<void>) {
                  action = const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (state is MutationSuccess<void>) {
                  subtitle = 'Archived';
                  action = Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  );
                } else if (state is MutationError<void>) {
                  subtitle = state.errorInfo.message;
                  action = IconButton(
                    tooltip: 'Retry',
                    onPressed: () => _archiveTask(task.$1),
                    icon: const Icon(Icons.refresh),
                  );
                } else {
                  action = IconButton(
                    tooltip: 'Archive',
                    onPressed: () => _archiveTask(task.$1),
                    icon: const Icon(Icons.archive_outlined),
                  );
                }

                return ListTile(
                  title: Text(task.$2),
                  subtitle: subtitle == null ? null : Text(subtitle),
                  trailing: action,
                );
              },
            ),
        ],
      ),
    );
  }
}