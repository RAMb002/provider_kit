import 'package:example/widgets/shared/notifiers/feedback_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates passing a locally owned Mutation directly to StateBuilder.
class MutationSelectExample extends StatefulWidget {
  const MutationSelectExample({super.key});

  @override
  State<MutationSelectExample> createState() => _MutationSelectExampleState();
}

class _MutationSelectExampleState extends State<MutationSelectExample> {
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
                StateBuilder.select(
                  selector: (FeedbackNotifier notifier) =>
                      notifier.sendMutation,
                  builder: (context, state, child) {
                    return state.when(
                      idle: () => FilledButton(
                        onPressed: () async {
                          final MutationResult result = await feedbackNotifier
                              .sendFeedback(_textField.text);
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
