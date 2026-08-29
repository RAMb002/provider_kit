## Unreleased

**Added**

- Added `ProviderKit.configure()` for one-time global configuration.
- Added `ErrorInfo` and `ErrorInfoMapper` for centralized error handling.
- Added global `NotifierObserver` configuration through
  `ProviderKit.configure()`.
- Added `whenOrNull()` and `mapOrNull()` to `ViewState` and `MutationState`
  for handling selected states without requiring a fallback.

**Breaking**

- Updated `ErrorState` to require the original `error` and `stackTrace`, with
  optional `errorInfo` and `onRetry`.
- `ErrorState` and `MutationError` now expose mapped `ErrorInfo` alongside the
  original error and stack trace.
- `ErrorState` and `MutationError` automatically resolve `ErrorInfo` through
  the configured `ErrorInfoMapper` when no `ErrorInfo` is provided.
- Updated `ViewState` error callbacks to receive
  `(ErrorInfo, Object, StackTrace, VoidCallback?)`.
- Updated `MutationState` error callbacks to receive
  `(ErrorInfo, Object, StackTrace)`.
- Global notifier observation now uses `ProviderKit.configure(observer: ...)`
  instead of direct `NotifierBase` configuration.

## 0.3.0

**Mutations**
- Added `Mutation` for managing the state of asynchronous operations.
- Added `MutationGroup` for managing independent mutations by key.
- Added automatic disposal for keyed mutations in `MutationGroup`.
- Added configurable `KeepAliveState` support for preserving completed mutation states.
- Added `MutationState` pattern-matching helpers: `when`, `maybeWhen`, `map`, and `maybeMap`.
- Added convenience state getters: `isIdle`, `isLoading`, `isSuccess`, and `isError`.
- Added access to successful mutation results through `Mutation.data`.
<br>

**State Widgets and ViewState Widgets**
- Added `.of` constructors to:
  - `StateBuilder`
  - `StateListener`
  - `StateConsumer`
  - `ViewStateBuilder`
  - `ViewStateListener`
  - `ViewStateConsumer`

  `.of` resolves the provider from the widget tree using `P` and `T` generics.

  ```dart
  StateBuilder.of<MyProvider, MyState>(builder: ...)
  ```

- **Breaking:**
  - Renamed `shouldCallListenerOnInit` to `callListenerOnInit`.
  - All `State Widgets` and `ViewState Widgets` now use one generic (`T`) instead of two.
  - The `provider` parameter is now required in the main constructor.

    Before:
    ```dart
    StateBuilder<MyProvider, MyState>(
      provider: myProvider,
      ...
    )
    ```

    After:
    ```dart
    StateBuilder<MyState>(
      provider: myProvider,
      ...
    )
    ```

  - Context-based lookup is now available through `.of`.

    Before:
    ```dart
    StateBuilder<MyProvider, MyState>(builder: ...)
    ```

    After:
    ```dart
    StateBuilder.of<MyProvider, MyState>(builder: ...)
    ```

  - Removed the `NotifierBuilder`, `NotifierListener`, and `NotifierConsumer` aliases introduced in `0.1.0`.
    - Use `StateBuilder`, `StateListener`, and `StateConsumer` instead.
<br>

**Testing**
- Added test coverage for `Mutation`.
- Updated existing test cases for state and widget functionality.
<br>

**Documentation**
- Updated documentation and examples for the latest API changes.
- Published the new **ProviderKit Snippets** VS Code extension for common ProviderKit templates.

## 0.2.0

- **Breaking:** Renamed `ProviderKit` to `AsyncViewStateNotifier`.
- Replaced `StateNotifier` with `StateValueListenable` as the shared abstraction for ProviderKit state widgets.
- Generalized all state and multi-state widgets to support any `StateValueListenable`.
- Fixed an issue where `AsyncViewStateNotifier` could continue updating state after being disposed.
- Added `mounted` to all notifiers to safely guard asynchronous operations against disposal.
- Updated testcases
- Improved documentation and README with clearer explanations and usage examples.

## 0.1.0

- Added `NotifierBuilder`, `NotifierListener`, and `NotifierConsumer` aliases to eliminate verbose `<StateNotifier<T>, T>` generics on `State Widgets` when passing a `StateNotifier` directly.

  ```dart
  // Before
  StateBuilder<StateNotifier<int>, int>(provider: notifier, ...)

  // After
  NotifierBuilder<int>(provider: notifier, ...)
  ```

## 0.0.2

- Added comprehensive test suite with over 340 test cases.
- Fixed core bugs in base widgets.
- Added override feature to `ViewStateWidgetProvider`.
- Improved and expanded package documentation.

## 0.0.1

- Initial release of `provider_kit`.
- A complementary toolkit designed to augment the `provider` package with advanced state management utilities.
- Introduces a flexible state container and a suite of reactive widgets to consume state updates seamlessly.
- Provides built-in utilities for handling loading, error, and data states with minimal boilerplate.
- Includes optional mixins for state caching and lifecycle observation.

For a full list of available widgets and classes, please refer to the package documentation.