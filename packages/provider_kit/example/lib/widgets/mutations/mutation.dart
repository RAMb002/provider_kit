import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates managing a single asynchronous operation with Mutation.
class MutationExample extends StatefulWidget {
  const MutationExample({super.key});

  @override
  State<MutationExample> createState() => _MutationExampleState();
}

class _MutationExampleState extends State<MutationExample> {
  late final _saveMutation = Mutation<int>(
    concurrency: MutationConcurrency.ignoreIfBusy,
  );

  int _attempt = 0;

  @override
  void dispose() {
    _saveMutation.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    await _saveMutation.run(() async {
      await Future.delayed(const Duration(seconds: 2));

      final attempt = ++_attempt;

      if (attempt == 1) {
        throw StateError('Failed to save changes.');
      }

      return attempt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StateBuilder<MutationState<int>>(
      listenable: _saveMutation,
      builder: (context, state, child) {
        final theme = Theme.of(context);
        final isLoading = state is MutationLoading<int>;
        final isError = state is MutationError<int>;
        final isSuccess = state is MutationSuccess<int>;

        Widget status;

        if (isLoading) {
          status = const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Saving changes...'),
            ],
          );
        } else if (isSuccess) {
          status = const Text('Changes saved successfully.');
        } else if (isError) {
          status = Text(
            (state).errorInfo.message,
            style: TextStyle(color: theme.colorScheme.error),
          );
        } else {
          status = const Text('Ready to save changes.');
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save_outlined, size: 36),
                const SizedBox(height: 16),
                Text(
                  'Save Profile',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                status,
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : _saveChanges,
                  child: Text(
                    isError
                        ? 'Retry'
                        : isSuccess
                            ? 'Save Again'
                            : 'Save Changes',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}