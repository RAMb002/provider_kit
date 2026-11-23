part of 'mutation.dart';

/// Defines how a mutation handles multiple execution requests.
enum MutationConcurrency {
  /// Starts every execution immediately.
  ///
  /// Every execution can publish its outcome and invoke its callbacks.
  /// The mutation state reflects the outcome of the most recently completed
  /// action.
  parallel,

  /// Starts new executions immediately, superseding older executions whose
  /// outcomes have not yet been committed.
  ///
  /// Older executions continue running, but their outcomes are ignored
  /// and return [MutationIgnored] with [MutationIgnoreReason.replaced].
  latestOnly,

  /// Ignores new executions while another execution is active.
  ///
  /// The ignored execution never starts and returns [MutationIgnored]
  /// with [MutationIgnoreReason.busy].
  ignoreIfBusy,

  /// Queues executions and runs them sequentially in submission order.
  ///
  /// Every accepted execution runs and can publish its outcome, unless
  /// invalidated by reset or disposal.
  queue,
}
