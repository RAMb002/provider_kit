import 'package:example/widgets/shared/notifiers/feedback_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates passing a locally owned Mutation directly to StateBuilder.
class MutationDirectExample extends StatefulWidget {
  const MutationDirectExample({super.key});

  @override
  State<MutationDirectExample> createState() => _MutationDirectExampleState();
}

class _MutationDirectExampleState extends State<MutationDirectExample> {
  final _textField = TextEditingController();
  final FeedbackNotifier _feedbackNotifier = FeedbackNotifier();

  @override
  void dispose() {
    _feedbackNotifier.dispose();
    _textField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            maxLines: 1,
            decoration: const InputDecoration(
              hintText: 'Write your feedback...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          StateBuilder(
            listenable: _feedbackNotifier.sendMutation,
            builder: (context, state, child) {
              return state.when(
                idle: () => FilledButton(
                  onPressed: () async {
                    final MutationResult result =
                        await _feedbackNotifier.sendFeedback(_textField.text);
                    result.when(succeeded: (data) {
                      debugPrint("successfully sent");
                    }, errored: (errorInfo, error, stackTrace) {
                      //handle error
                    }, ignored: (reason) {
                      //handle ignore if needed
                    });
                  },
                  child: const Text('Send Feedback'),
                ),
                loading: () => const Center(
                  child: SizedBox.square(
                    dimension: 25,
                    child: CircularProgressIndicator(),
                  ),
                ),
                success: (message) => Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _feedbackNotifier.sendMutation.reset,
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
