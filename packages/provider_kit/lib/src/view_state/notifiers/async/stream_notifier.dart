part of 'async_notifiers.dart';

/// {@template provider_kit.stream_notifier.basic_usage}
/// An asynchronous notifier that manages data updates through a [Stream].
///
/// Subclasses implement [build] to provide the stream for the current inputs.
/// ProviderKit manages subscription setup, state transitions, refreshes,
/// rebuilds, and the validity of stream events.
///
/// ### Basic Usage
///
/// ```dart
/// class MessagesNotifier extends StreamNotifier<List<Message>> {
///   MessagesNotifier(this._repository);
///
///   final MessageRepository _repository;
///
///   @override
///   Stream<List<Message>> build() {
///     return _repository.watchMessages();
///   }
/// }
/// ```
/// {@endtemplate}
///
/// {@macro provider_kit.async_view_state_notifier_base.constructors_param}
///
/// {@template provider_kit.stream_notifier.default_behaviour}
///
/// ### Default behavior
///
/// ProviderKit listens to the stream returned by [build] and publishes its
/// events automatically:
///
/// - An emitted value becomes [DataState], unless it is an empty [Iterable]
///   and [enableEmptyState] is `true`, in which case it becomes [EmptyState].
/// - A stream error transitions to [ErrorState] when no existing data or error
///   state needs to be preserved. Otherwise, the error is reported without
///   replacing the current state.
/// - When the stream completes without emitting data or errors and no existing
///   data needs to be preserved, the state becomes [EmptyState].
///
/// State assignments made from within [build] are protected against outdated
/// generations. However, implementations should generally return a stream
/// rather than use direct state assignments to publish stream events.
///
/// {@endtemplate}
///
/// {@macro provider_kit.async_view_state_notifier_base.state_messages}
///
/// {@template provider_kit.stream_notifier.about}
///
/// ### Rebuilding
///
/// Call [rebuild] when inputs that determine the stream change. It invalidates
/// the current generation immediately and schedules a replacement subscription.
///
/// Multiple requests made before the replacement starts are coalesced into one
/// operation using the latest inputs.
///
/// The previous subscription is cancelled before the replacement stream is
/// created and subscribed to. ProviderKit waits for the subscription's
/// cancellation cleanup to complete before establishing the replacement.
///
/// If a build is superseded while a caller is awaiting [rebuild], the returned
/// future follows the replacement rather than waiting for outdated setup work
/// to finish. Errors from outdated operations are ignored; an error from the
/// latest relevant operation is propagated with its original stack trace.
///
/// Events and state assignments from outdated builds cannot change the current
/// state.
///
/// ### Refreshing
///
/// [refresh] restarts the subscription using the current inputs. Existing data
/// remains visible while the replacement subscription is established.
///
/// If a valid setup operation is already running, refresh joins that operation.
/// If it becomes outdated while waiting, refresh follows the replacement.
///
/// Setup failures are propagated to callers that await [refresh]. Errors emitted
/// by the stream are handled through its error callback and cannot generally be
/// propagated through the future returned by [refresh].
///
/// ### Invalidating the current build
///
/// Call [invalidateBuild] when the current build and its subscription should be
/// invalidated without starting a replacement.
///
/// ```dart
/// invalidateBuild();
/// ```
///
/// This invalidates pending or running build operations and cancels the active
/// stream subscription. Subsequent events from the invalidated subscription and
/// state assignments from its build generation are ignored.
///
/// The notifier's current [state] is left unchanged. Any operations waiting for
/// the invalidated build complete normally; they do not wait for a replacement
/// operation to start.
///
/// Subscription cancellation may still be completing when invalidation returns.
/// A later [refresh] or [rebuild] waits for that cleanup to finish before
/// establishing a new subscription.
///
/// Invalidating a build does not automatically start another one. Call
/// [refresh] or [rebuild] when a new subscription is needed.
/// {@endtemplate}
///
/// {@macro provider_kit.async_view_state_notifier_base.state_setters}
///
/// {@macro provider_kit.async_view_state_notifier_base.check_staleness}

abstract class StreamNotifier<T> extends _AsyncViewStateNotifierBase<T> {
  /// {@macro provider_kit.stream_notifier.basic_usage}
  /// {@macro provider_kit.async_view_state_notifier_base.constructors_param}
  /// {@macro provider_kit.stream_notifier.default_behaviour}
  /// {@macro provider_kit.async_view_state_notifier_base.state_messages}
  /// {@macro provider_kit.stream_notifier.about}
  /// {@macro provider_kit.async_view_state_notifier_base.state_setters}
  /// {@macro provider_kit.async_view_state_notifier_base.check_staleness}
  StreamNotifier({
    super.initialState,
    super.startInitialBuild,
    super.enableEmptyState,
    super.loadingMessage,
    super.emptyMessage,
  });

  StreamSubscription<T>? _subscription;

  /// Tracks cancellation of the previous stream subscription.
  ///
  /// A new subscription waits until the previous subscription's cleanup
  /// has completed.
  Future<void> _subscriptionCancellation = Future<void>.value();

  bool _hasReceivedData = false;
  bool _hasReceivedError = false;

  /// Builds the stream for the current inputs.
  ///
  /// Subclasses must implement this method. When the inputs change, call
  /// [rebuild] to replace the current subscription.
  ///
  /// Return a stream rather than assigning [state] directly to publish stream
  /// values. Any state assignments made within this method are protected
  /// against outdated build generations.
  @protected
  Stream<T> build();

  @override
  Future<void> _executeBuild(int token, AsyncBuildReason reason) async {
    if (!_isCurrentBuild(token)) return;

    try {
      // Detach the old subscription before notifying listeners. Its events
      // are already stale because the manager has issued a new generation.
      final previousSubscription = _subscription;
      _subscription = null;

      _hasReceivedData = false;
      _hasReceivedError = false;

      _prepareBuild(reason);

      // Always cancel the old subscription, even if a listener requested
      // another rebuild or disposed this notifier during the state change.
      await _cancelSubscription(
        previousSubscription,
        errorMessage:
            'While cancelling the previous stream subscription '
            'for $runtimeType',
      );

      if (!_isCurrentBuild(token)) return;

      // Both stream creation and listening happen inside the token Zone.
      //
      // This matters for async* generators: their bodies execute as the
      // stream is listened to, and may assign state after an await.
      await runZoned<Future<void>>(() async {
        final stream = build();

        // build() can synchronously trigger another rebuild or disposal.
        if (!_isCurrentBuild(token)) return;

        await _subscribe(stream, token);
      }, zoneValues: {_buildZoneKey: token});
    } catch (error, stackTrace) {
      _handleBuildError(token, error, stackTrace);
    }
  }

  /// Applies the default error policy to a failed subscription setup.
  ///
  /// Existing data is preserved and the error is reported. Without usable
  /// data, the notifier transitions to [ErrorState].
  ///
  /// The original failure is rethrown so an explicitly awaited refresh or
  /// rebuild can receive it.
  void _handleBuildError(int token, Object error, StackTrace stackTrace) {
    if (!_isCurrentBuild(token)) return;

    if (state.isData || state.isError) {
      dispatchErrorToObserver(error, stackTrace);
    } else {
      setError(error, stackTrace);
    }

    // Error handling and observer callbacks can trigger another operation.
    if (!_isCurrentBuild(token)) return;

    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<void> _subscribe(Stream<T> stream, int token) async {
    var subscriptionDone = false;

    final subscription = stream.listen(
      (data) => _handleData(token, data),
      onError: (Object error, StackTrace stackTrace) {
        _handleError(token, error, stackTrace);
      },
      onDone: () {
        subscriptionDone = true;
        _handleDone(token);
      },
    );

    // Synchronous streams may emit data, errors, or completion before
    // listen() returns. Their callbacks can also trigger rebuild or disposal.
    if (!_isCurrentBuild(token)) {
      await _cancelSubscription(
        subscription,
        errorMessage:
            'While cancelling an outdated stream subscription '
            'for $runtimeType',
      );
      return;
    }

    // A synchronous stream may already have completed during listen().
    if (!subscriptionDone) {
      _subscription = subscription;
    }
  }

  void _handleData(int token, T data) {
    if (!_isCurrentBuild(token)) return;

    _hasReceivedData = true;

    if (_isEmptyState(data)) {
      setEmpty();
    } else {
      state = DataState<T>(data);
    }
  }

  /// Handles an error emitted after subscription setup.
  ///
  /// Such errors cannot be propagated through an already-completed setup
  /// future. They are handled through state and observer notifications.
  void _handleError(int token, Object error, StackTrace stackTrace) {
    if (!_isCurrentBuild(token)) return;

    _hasReceivedError = true;

    runZoned<void>(() {
      if (state.isData || state.isError) {
        dispatchErrorToObserver(error, stackTrace);
      } else {
        setError(error, stackTrace);
      }
    }, zoneValues: {_buildZoneKey: null});
  }

  void _handleDone(int token) {
    if (!_isCurrentBuild(token)) return;

    _subscription = null;

    // Preserve existing data, and do not replace an error state with empty
    // merely because the stream completed without emitting data.
    if (!_hasReceivedData && !_hasReceivedError && !state.isData) {
      setEmpty();
    }
  }

  @override
  void _invalidateBuildResources() {
    _cancelActiveSubscription(
      errorMessage:
          'While cancelling an invalidated stream subscription for $runtimeType',
    );
  }

  @override
  void _disposeAsyncResources() {
    _cancelActiveSubscription(
      errorMessage: 'While cancelling the stream subscription for $runtimeType',
    );
  }

  void _cancelActiveSubscription({required String errorMessage}) {
    final subscription = _subscription;
    _subscription = null;

    _hasReceivedData = false;
    _hasReceivedError = false;

    _cancelSubscription(subscription, errorMessage: errorMessage).ignore();
  }

  Future<void> _cancelSubscription(
    StreamSubscription<T>? subscription, {
    required String errorMessage,
  }) {
    if (subscription == null) {
      return _subscriptionCancellation;
    }

    final cancellation = _cancelSubscriptionSafely(subscription, errorMessage);
    _subscriptionCancellation = cancellation;
    return cancellation;
  }

  Future<void> _cancelSubscriptionSafely(
    StreamSubscription<T> subscription,
    String errorMessage,
  ) async {
    try {
      await subscription.cancel();
    } catch (error, stackTrace) {
      reportErrorToFlutter(error, stackTrace, message: errorMessage);
    }
  }
}
