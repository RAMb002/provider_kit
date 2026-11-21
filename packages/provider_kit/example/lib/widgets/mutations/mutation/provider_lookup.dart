import 'package:example/widgets/shared/notifiers/feedback_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates passing a locally owned Mutation directly to StateBuilder.
class MutationProviderExample extends StatefulWidget {
  const MutationProviderExample({super.key});

  @override
  State<MutationProviderExample> createState() =>
      _MutationProviderExampleState();
}

class _MutationProviderExampleState extends State<MutationProviderExample> {
  final _textField = TextEditingController();

  @override
  void dispose() {
    _textField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => FeedbackNotifier(),
        builder: (context, _) {
          final feedbackNotifier = context.read<FeedbackNotifier>();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.feedback_outlined, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Share your feedback',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Let us know what you think.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _textField,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write your feedback...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                StateBuilder.of<FeedbackNotifier, MutationState<String>>(
                  selectListenable: (notifier) => notifier.sendMutation,
                  builder: (context, state, child) {
                    return state.when(
                      idle: () => FilledButton(
                        onPressed: () =>
                            feedbackNotifier.sendFeedback(_textField.text),
                        child: const Text('Send Feedback'),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      success: (message) => Column(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: feedbackNotifier.sendMutation.reset,
                            child: const Text('Send another'),
                          ),
                        ],
                      ),
                      error: (errorInfo, error, stackTrace) => Column(
                        children: [
                          Text(
                            errorInfo.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // FilledButton(
                          //   onPressed: _sendFeedback,
                          //   child: const Text('Retry'),
                          // ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}
