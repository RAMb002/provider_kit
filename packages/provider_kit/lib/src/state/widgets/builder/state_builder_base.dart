part of 'state_builder.dart';

/// Base class for [StateBuilder] implementations.
///
/// Provides the shared provider, rebuild predicate, and child configuration
/// used by state-based builder widgets.
abstract class StateBuilderBase<P extends StateValueListenable<T>, T>
    extends StateBuilder<T> {
  const StateBuilderBase({
    super.key,
    this.provider,
    super.rebuildWhen,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.state_listener.provider}
  final P? provider;

  /// The function that builds the widget tree based on the current state.
  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<StateBuilderBase<P, T>> createState() => _StateBuilderBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<P?>('provider', provider));
  }
}

/// The state class for [StateBuilderBase].
class _StateBuilderBaseState<P extends StateValueListenable<T>, T>
    extends State<StateBuilderBase<P, T>> {
  late T _state;
  late P _provider;

  /// Whether a rebuild has already been scheduled for the current frame.
  ///
  /// This prevents multiple deferred rebuild callbacks from being registered
  /// when several dependency notifications occur during the same build phase.
  final RebuildScheduler _rebuildScheduler = RebuildScheduler();

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    _state = _currentState;
  }

  @override
  void didUpdateWidget(StateBuilderBase<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? oldProvider;
    if (oldProvider != currentProvider) {
      _provider = widget.provider ?? _readProvider;
      _state = _currentState;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.provider ?? _readProvider;
    if (_provider != provider) {
      _provider = provider;
      _state = _currentState;
    }
  }

  /// Requests a rebuild of this widget.
  ///
  /// If a rebuild is requested while the widget tree is being built, the
  /// rebuild is deferred until after the current frame to avoid marking the
  /// widget dirty during the build phase. Multiple rebuild requests during the
  /// same build phase are coalesced into a single deferred rebuild.
  ///
  /// Otherwise, the rebuild is requested immediately.
  void _requestRebuild(T state) {
    _state = state;

    _rebuildScheduler.request(
      isMounted: () => mounted,
      rebuild: () => setState(() {}),
    );
  }

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  /// Gets the current state from the provider.
  T get _currentState => _provider.state;

  @override
  Widget build(BuildContext context) {
    if (widget.provider == null) {
      context.select<P, bool>((provider) => identical(_provider, provider));
    }
    return StateListener<T>(
      provider: _provider,
      listenWhen: widget.rebuildWhen,
      listener: (context, state) => _requestRebuild(state),
      child: widget.build(context, _state, widget.child),
    );
  }
}
