import 'package:example/widgets/shared/repositories/feedback_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:provider_kit/provider_kit.dart';

class FeedbackNotifier extends ChangeNotifier {
  FeedbackNotifier();

  final FeedbackRepository _repository = FeedbackRepository();

  final sendMutation = Mutation<String>(
    concurrency: MutationConcurrency.ignoreIfBusy,
  );

  Future<MutationResult<String>> sendFeedback(String message) {
    return sendMutation.run(
      () => _repository.sendFeedback(message),
    );
  }

  @override
  void dispose() {
    sendMutation.dispose();
    super.dispose();
  }
}