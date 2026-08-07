## Unreleased

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