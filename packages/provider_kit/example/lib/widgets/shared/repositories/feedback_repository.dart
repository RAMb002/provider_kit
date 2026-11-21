class FeedbackRepository {
  Future<String> sendFeedback(String message) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'Thank you! Your feedback has been received.';
  }
}
