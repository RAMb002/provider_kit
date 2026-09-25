[![Build](https://github.com/RAMb002/provider_kit/actions/workflows/build.yml/badge.svg)](https://github.com/RAMb002/provider_kit/actions/workflows/build.yml)
<a href="https://codecov.io/gh/RAMb002/provider_kit"><img src="https://codecov.io/gh/RAMb002/provider_kit/branch/main/graph/badge.svg" alt="codecov">
[![License: BSD 2-Clause](https://img.shields.io/badge/License-BSD%202--Clause-blue.svg)](https://opensource.org/license/bsd-2-clause/)


<p align="center">
  <img src="https://github.com/user-attachments/assets/76d037a7-16b0-4d77-92f0-18fa7d815ba9"
   width="100%"
   alt="ProviderKit"
   style="border-radius: 16px;"
   />
</p>

---

**ProviderKit** is a Flutter toolkit built on top of `ChangeNotifier` and
`Listenable`, designed to work alongside the
[`provider`](https://pub.dev/packages/provider) package for dependency
injection and widget-tree integration.

ProviderKit extends the `ChangeNotifier` pattern with reusable building blocks
for state management, asynchronous UI states, mutations, caching, lifecycle
management, and observation.

---

### Why ProviderKit?

Building applications with `ChangeNotifier` often means repeatedly writing
boilerplate for state handling, async states, listeners, mutations, and state
caching.

ProviderKit provides reusable components for these common patterns while
remaining compatible with the `provider` ecosystem, so you can keep the
architecture you already know while writing less boilerplate.

## Features

- **Enhanced Notifiers** — Specialized notifiers for managing structured state
  and asynchronous operations.
- **State Widgets** — Builders and listeners for reacting to state changes and
  handling side effects.
- **View State** — Built-in initial, loading, empty, error, and data states for
  asynchronous UI flows.
- **Reusable State Widgets** — Define default view-state widgets once and reuse
  them across your application.
- **Mutations** — Dedicated handling for user-triggered operations with loading,
  success, and error states.
- **Multi-State Support** — Combine multiple state sources in a single widget.
- **State Caching** — Save and restore view state data when needed.
- **Notifier Observation** — Observe notifier lifecycle events and state changes.
- **Error Mapping** — Map application errors into consistent error messages and codes.
- **Resource Lifecycle** — Automatically manage resources such as mutations,
  debounces, and throttles.

## Contents

- [Getting started](#getting-started)
- [ProviderKit configuration](#providerkit-configuration)
- [State](#state)
  - [State Notifier](#statenotifier)
  - [State Widgets](#state-widgets)
  - [Multi State Widgets](#multi-state-widgets)
- [View State](#viewstate)
  - [View State Notifier](#viewstatenotifier)
  - [Async View State Notifier](#asyncviewstatenotifier)
  - [View State Widgets Provider](#viewstatewidgetsprovider)
  - [View State Widgets](#view-state-widgets)
  - [Multi View State Widgets](#multi-view-state-widgets)
  - [Cache Mixins](#cache-mixins)
- [Mutations](#mutations)
  - [MutationState](#mutationstate)
  - [MutationGroup](#mutationgroup)
- [Automatic Resource Disposal](#automatic-resource-disposal)
- [Nested State Listener](#nestedstatelistener)
- [Notifier Observer](#notifierobserver)
- [VS Code Extension](#vs-code-extension)

---

## Getting started

#### Add them to your `pubspec.yaml` file
```yaml
dependencies:
  provider_kit: ^0.4.0
  provider: ^6.1.5 # For dependency injection
  ```
### Provider integration

ProviderKit works with the [`provider`](https://pub.dev/packages/provider)
package and is designed to integrate naturally with its dependency injection
and widget-tree provider system.

```dart
ChangeNotifierProvider(
  create: (_) => MyProvider(),
  child: const MyApp(),
)
```

ProviderKit widgets can then resolve the provider from the widget tree when
using their `.of` constructors.
For complete documentation on dependency injection and provider registration,
see the [`provider`](https://pub.dev/packages/provider) package documentation.

## ProviderKit configuration

ProviderKit configuration is optional. Configure it once at application
startup to set global error mapping and notifier observation.

```dart
void main() {
  ProviderKit.configure(
    observer: MyNotifierObserver(),
    errorInfoMapper: (error, stackTrace) {
      if (error is AuthException) {
        return ErrorInfo(
          message: error.message ?? 'Authentication failed.',
          code: error.code,
        );
      }

      return ErrorInfo(
        message: error.toString(),
      );
    },
  );

  runApp(const MyApp());
}
```

- `errorInfoMapper` converts application errors into `ErrorInfo`.
- `observer` receives notifier lifecycle and state-change notifications.

For detailed usage, see [Notifier Observer](#notifierobserver) and the
error-handling examples in [View State](#viewstate).

## State

ProviderKit provides reusable notifiers and widgets for managing application
state and reacting to state changes.

### StateNotifier

`StateNotifier` is the core notifier provided by ProviderKit. It is similar to
Flutter's `ValueNotifier`, but provides additional capabilities for building
application state.

By extending `StateNotifier`, your providers become observable, allowing
widgets to listen to state changes and react when the state is updated.

```dart
class MyProvider extends StateNotifier<int> {
  MyProvider() : super(0);

  void increment() => state++;
  void decrement() => state--;
}
```

## State Widgets

State Widgets provide a simple way to listen to state changes and rebuild your
UI in response to updates from a ProviderKit notifier.
<p>
  <img
    src="https://github.com/user-attachments/assets/e5a1b3d2-6e95-4bcf-aa31-b88a5dd10046"
    width="354"
    height="240"
    alt="State Widgets Demo"
  />
</p>

The following widgets are available:

- [`StateListener`](#statelistener) — listens for state changes and performs side effects.
- [`StateBuilder`](#statebuilder) — rebuilds the UI when the state changes.
- [`StateConsumer`](#stateconsumer) — combines listening and rebuilding in one widget.

Each widget supports two ways to access the provider:

1. **Explicitly** — pass the provider instance through the `provider` parameter.
2. **From context** — use the `.of` constructor to resolve the provider from
   the widget tree.


When using the `.of` constructor, the provider must be available in the widget
tree through `Provider`, `ChangeNotifierProvider`, or another compatible
provider widget from the [`provider`](https://pub.dev/packages/provider)
package.


## StateListener

A widget that listens for state changes and executes side effects without rebuilding the UI.

```dart
// Explicit provider
StateListener<MyDataType>(
  provider: provider,
  listenWhen: (previous, current) => previous != current, // Default, optional
  callListenerOnInit: false, // Default, optional
  listener: (context, state) {
    // Can execute side effects here
  },
  child: YourWidget(),
);

```
```dart
// Provider from context
StateListener.of<MyProvider, MyDataType>(
  listener: (context, state) { /* side effects */ },
  child: YourWidget(),
);
```

## StateBuilder

A widget that rebuilds the UI when the provider's state changes.

```dart
// Explicit provider
StateBuilder<MyDataType>(
  provider: provider,
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, state, child) {
    return Text('Count: $state');
  },
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```
```dart
// Provider from context
StateBuilder.of<MyProvider, MyDataType>(
  builder: (context, state, child) => Text('$state'),
);
```

## StateConsumer

A widget that combines the features of `StateListener` and `StateBuilder`,
allowing you to listen for state changes and rebuild the UI from the same
provider.

```dart
// Explicit provider
StateConsumer<MyDataType>(
  provider: provider,
  listenWhen: (previous, current) => previous != current, // Default, optional
  callListenerOnInit: false, // Default, optional
  listener: (context, state) {
    // Can execute side effects here
  },
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, state, child) {
    return Text('Count: $state');
  },
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```
```dart
// Provider from context
StateConsumer.of<MyProvider, MyDataType>(
  listener: (context, state) { /* side effects */ },
  builder: (context, state, child) => Text('$state'),
);
```
> **Tip:** `State Widgets` work with any notifier
> provided by ProviderKit, not just `StateNotifier`.

---

## Multi State Widgets

Multi State Widgets allow a single widget to listen to multiple providers at
the same time.

<p>
  <img
    src="https://github.com/user-attachments/assets/f67ebb34-9435-4c43-9ed1-6c2e93df631a"
    width="338"
    height="270"
    alt="Multi State Widgets Demo"
  />
</p>

The following widgets are available:

- [`MultiStateListener`](#multistatelistener) — listens for state changes from multiple providers.
- [`MultiStateBuilder`](#multistatebuilder) — rebuilds the UI when the state of any provider changes.
- [`MultiStateConsumer`](#multistateconsumer) — combines listening and rebuilding for multiple providers.

Unlike the single-provider State Widgets, Multi State Widgets receive their
providers through the `providers` parameter and do not resolve them from the
widget tree.

The provided states can be of the same type or different types.

## MultiStateListener

A widget that listens for state changes from multiple providers and executes a
side effect when any of their states change.

```dart
MultiStateListener<MyDataType>(
  providers: [provider1, provider2, provider3],
  listenWhen: (previous, current) => previous != current, // Default, optional
  callListenerOnInit: false, // Default, optional
  listener: (context, states) {
    // Can execute side effects here
  },
  child: YourWidget(),
);
```

## MultiStateBuilder

A widget that rebuilds the UI when the state of any of its providers changes.

```dart
MultiStateBuilder<MyDataType>(
  providers: [provider1, provider2, provider3],
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, states, child) => Text(states.toString()),
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```

## MultiStateConsumer

A widget that combines the features of `MultiStateListener` and
`MultiStateBuilder`, allowing you to listen to and rebuild from multiple
providers.

```dart
MultiStateConsumer<MyDataType>(
  providers: [provider1, provider2, provider3],
  listenWhen: (previous, current) => previous != current, // Default, optional
  callListenerOnInit: false, // Default, optional
  listener: (context, states) {
    // Can execute side effects here
  },
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, states, child) {
    return Text(states.toString());
  },
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```
> **Tip:** `Multi State Widgets` work with any notifier
> provided by ProviderKit, not just `StateNotifier`.


---

Now that we've covered the core state-management building blocks, let's move
on to ProviderKit's higher-level features for handling common application
workflows.

## ViewState

`ViewState` represents the different states a view can have, including
`InitialState`, `LoadingState`, `DataState`, `EmptyState`, and `ErrorState`.

It is particularly useful for managing data displayed by a view, such as data loaded from a server or local storage, where the UI needs to represent different stages of the data lifecycle.

<p>
  <img
    src="https://github.com/user-attachments/assets/0a8736e6-56c3-4c8d-9774-5a67a9954396"
     width="325.5"
     height="262.5"
    alt="View State Widgets Demo"
  />
</p>


| State            | Description                                                       | Properties |
|-----------------|-------------------------------------------------------------------|------------|
| `InitialState`  | Represents the initial state of a view.                          | None       |
| `LoadingState`  | Represents a loading state with optional progress and message.   | `message: String?`, `progress: double?` |
| `DataState`     | Represents a successful data state containing the result object. | `data: T` |
| `EmptyState`    | Represents an empty state with an optional message.              | `message: String?` |
| `ErrorState` | Represents an error state containing mapped error information, the original error, its stack trace, and an optional retry callback. | `errorInfo: ErrorInfo`, `error: Object`, `stackTrace: StackTrace`, `onRetry: VoidCallback?` |

### Error information


`ErrorState` contains the mapped `errorInfo`, the original `error`, its
`stackTrace`, and an optional `onRetry` callback.

You can provide `errorInfo` explicitly when you want to define the error
information yourself:

```dart
final state = ErrorState(
  error,
  stackTrace,
  errorInfo: const ErrorInfo(
    message: 'An error occurred.',
    code: 'unknown_error',
  ),
  onRetry: retry,
);
```

When `errorInfo` is omitted, ProviderKit automatically creates it using the
`ErrorInfoMapper` configured through `ProviderKit.configure()`:

```dart
final state = ErrorState(
  error,
  stackTrace,
);

print(state.errorInfo.message);
print(state.errorInfo.code);
```

This allows application errors to be converted into consistent,
user-friendly `ErrorInfo` values that can be used directly by UI and
application logic.

For example, a listener can use the mapped information without needing to
handle the underlying exception type:

```dart
errorStateListener: (errorInfo, error, stackTrace, onRetry) {
  showToast(errorInfo.message);
}
```

### Handling ViewState

`ViewState` provides `when()`, `maybeWhen()`, `whenOrNull()`, `map()`,
`maybeMap()`, and `mapOrNull()` for handling its different states without
manually checking the state type.

Use `when()` when every state should be handled:

```dart
state.when(
  initialState: () => ...,
  loadingState: (message, progress) => ...,
  dataState: (data) => ...,
  emptyState: (message) => ...,
  errorState: (errorInfo, error, stackTrace, onRetry) => ...,
);
```
> **Note:** `EmptyState` will be used only for `Iterable` data types. For Example when your T is a `List`, `Set` etc.

## ViewStateNotifier

`ViewStateNotifier` is a `StateNotifier` that manages a `ViewState<T>`.
It provides a convenient way to represent and update the different states of
data-driven UI, such as loading, success, empty, and error states.

```dart
class MyViewStateProvider extends ViewStateNotifier<List<Item>> {
  final Repository _repo = Repository();

  MyViewStateProvider() : super(const InitialState()) {
    init();
  }

  Future<void> init() async {
    try {
      state = const LoadingState();
      final List<Item> items = await _repo.getItems(10);
      if (!mounted) return; // Guard against disposal
      if (items.isEmpty) {
        state = const EmptyState();
        return;
      }
      state = DataState(items);
    } catch (error, stackTrace) {
      state = ErrorState(
        error,
        stackTrace,
        onRetry: onRefresh,
      );
    }
  }

  void onRefresh() {
    state = const LoadingState();
    init();
  }
}
```
The notifier exposes the current `ViewState<T>` through `state`, allowing
widgets to react to each state through ProviderKit's View State widgets.

> **Note:** Use `mounted` to check whether the notifier is still alive before
> updating state after an asynchronous operation.



**Tired of manually implementing the same logic for every provider?**
No worries! Introducing **AsyncViewStateNotifier**—a more efficient way to manage our view state.


## AsyncViewStateNotifier

`AsyncViewStateNotifier` automatically handles much of the boilerplate required
for asynchronous `ViewState` management:

<table>
  <tr>
    <th align="center">Before</th>
    <th align="center">After</th>
  </tr>
  <tr valign="top">
    <td>
      <img
        src="https://github.com/user-attachments/assets/f98fd8ad-50bf-4fb5-9426-1ff17a8d6b65"
        alt="Before"
        width="100%"
        style="max-height: 600px;"
      >
    </td>
    <td>
      <img
        src="https://github.com/user-attachments/assets/315421e8-db67-4144-bd17-931e0ee455b4"
        alt="After"
        width="100%"
        style="max-height: 400px;"
      >
    </td>
  </tr>
</table>

Instead of manually managing loading, data, empty, error, and refresh states,
implement `fetchData()`:

```dart
class MyViewStateProvider extends AsyncViewStateNotifier<List<Item>> {
  @override
  FutureOr<List<Item>> fetchData() => Repository().getItems(10);
}

```

The notifier automatically manages the associated `ViewState` transitions,
error handling, empty-state handling, and refresh behavior.

> **Note:** By default, an empty `Iterable` result is represented by
> `EmptyState`. Use `disableEmptyState` to treat an empty `Iterable` as
> `DataState` instead.

### What does `AsyncViewStateNotifier` handle?
- Automatically fetches data upon initialization.  
- Transitions to `LoadingState` before fetching.  
- If the data is `Iterable` and if it's empty, it switches to `EmptyState`.  
- Catches errors and converts them into `ErrorState`.  
- Includes a built-in `refresh()` function to re-run the data-fetching logic.
- Passes the `refresh` function, error, and stack trace to `ErrorState`.  
- Internally guarded with `mounted` – For safe async state updates.  

> **Note:** `FlutterError` exceptions are **re-thrown** and are not converted
> to `ErrorState`. This prevents fatal programming errors, such as assertion
> failures, from being masked by the UI.


| **Attributes**         | **Type**                                  | **Description**  |
|-----------------------------|------------------------------------------|----------------|
| **Constructor Params**  |                                          |                |
| `initialState`              | `ViewState<T>`                           | The initial state of the provider. Defaults to `LoadingState`. |
| `disableEmptyState`         | `bool`                                   | By default, if `T` is an `Iterable` (like `List`, `Set`, etc.), an empty iterable will result in `EmptyState`. Setting this to `true` forces an empty iterable to be assigned as `DataState`. |
| **Property**               |                                          |                |
| `state`                     | `ViewState<T>`                           | The current state of the provider, which can be `LoadingState`, `DataState`, `EmptyState`, or `ErrorState`. |
| **Methods**                  |                                          |                |
| `init()`                     | `FutureOr<void>`                         | Runs on initialization, setting up states and **Guarded with try-catch block**. It won't execute again if already initialized unless `refresh` is called. |
| `fetchData()`                | `FutureOr<T>`                            | Fetches data from an API or database. Must be implemented in subclasses. |
| `errorStateObject()`         | `ErrorState<T>`                          | Helps to customize the default `ErrorState` Object |
| `loadingStateObject()`       | `LoadingState<T>`                        | Helps to customize the default `LoadingState` Object  |
| `emptyStateObject()`         | `EmptyState<T>`                          | Helps to customize the default `EmptyState` Object  instance. |
| `refresh()`                  | `Future<void>`                           | Refreshes the provider which will call `init` with `fetchData()` again. |


When `ErrorState.onRetry` is not provided, View State Widgets use the
`refresh()` method of the `AsyncViewStateNotifier` as the retry callback.

Before moving on to the widgets that listen to `ViewStateNotifier` and `AsyncViewStateNotifier`, let's first look at `ViewStateWidgetsProvider`, which allows us to define the default widgets used to represent different `ViewState`s.


## ViewStateWidgetsProvider

In a typical application, different `ViewState`s need different UI states—for
example, a loading indicator for `LoadingState`, an error widget for
`ErrorState`, an empty widget for `EmptyState`, and the actual content for
`DataState`.

Instead of configuring these widgets repeatedly for each View State widget,
`ViewStateWidgetsProvider` lets you define them once and reuse them throughout
the widget tree.

The configured widgets are used automatically by [`ViewStateBuilder`](#viewstatebuilder),
[`ViewStateConsumer`](#viewstateconsumer), [`MultiViewStateBuilder`](#multiviewstatebuilder),
and [`MultiViewStateConsumer`](#multiviewstateconsumer).

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

@override
Widget build(BuildContext context) {
  return ViewStateWidgetsProvider(
    initialStateBuilder: (isSliver) => MyInitialWidget(isSliver),
    loadingStateBuilder: (message, progress, isSliver) => MyLoadingWidget(
      message: message,
      progress: progress,
      isSliver: isSliver,
    ),
    emptyStateBuilder: (message, isSliver) => MyEmptyWidget(
      message: message,
      isSliver: isSliver,
    ),
    errorStateBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) =>
     MyErrorWidget(
      errorInfo: errorInfo,
      onRetry: onRetry,
      isSliver: isSliver,
    ),
    child: const MaterialApp(),
  );
}
}

```
Additionally, you can wrap any section of your widget tree with `ViewStateWidgetsProvider` to completely redefine its state widgets, or use `ViewStateWidgetsProvider.override` to update only specific state builders while inheriting the rest from the parent `ViewStateWidgetsProvider`.

```dart
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewStateWidgetsProvider.override(
      context: context,
      // Overrides ONLY the loading builder for this subtree, used internally by `ViewStateWidgets`.
      loadingStateBuilder: (message, progress, isSliver) {
        const widget = Center(child: ProfileSkeletonLoader());
        return isSliver ? const SliverToBoxAdapter(child: widget) : widget;
      },
      child: const ProfileView(),
    );
  }
}
```

With `ViewStateWidgetsProvider`, we can significantly reduce the amount of UI boilerplate:

<table>
  <tr>
    <th align="center">Before</th>
    <th align="center">After</th>
  </tr>
  <tr valign="top">
    <td>
      <img
        src="https://github.com/user-attachments/assets/63167856-c219-4587-8db9-14f4cd6bbc91"
        alt="Before"
        width="100%"
        style="max-height: 500px;"
      >
    </td>
    <td>
      <img
        src="https://github.com/user-attachments/assets/d247e875-0295-446c-8ca0-f4228c2dcb1e"
        alt="After"
        width="100%"
        style="max-height: 400px;"
      >
    </td>
  </tr>
</table>

## View State Widgets

View State Widgets are similar to [State Widgets](#state-widgets), but are
designed to work with [`ViewState`](#viewstate). They listen to providers that
extend [`ViewStateNotifier`](#viewstatenotifier) or
[`AsyncViewStateNotifier`](#asyncviewstatenotifier) and automatically respond to
changes between `InitialState`, `LoadingState`, `DataState`, `EmptyState`, and
`ErrorState`.

Each widget supports two ways to access the provider:

1. **Explicitly** — pass the provider instance through the `provider` parameter.
2. **From context** — use the `.of` constructor to resolve the provider from the
   widget tree.

When using the `.of` constructor, the provider must be available in the widget
tree through `Provider`, `ChangeNotifierProvider`, or another compatible
provider widget from the [`provider`](https://pub.dev/packages/provider)
package.

The following widgets are available:

- [`ViewStateListener`](#viewstatelistener) — listens to `ViewState` changes and
  executes state-specific side effects.
- [`ViewStateBuilder`](#viewstatebuilder) — builds the UI based on the current
  `ViewState`.
- [`ViewStateConsumer`](#viewstateconsumer) — combines listening and building in
  one widget.

## ViewStateListener
A widget that listens for `ViewState` changes and executes state-specific side effects without rebuilding the UI.

```dart
// Explicit provider
ViewStateListener<MyDataType>(
  provider: myProvider,
  dataStateListener: (data) => context.showToast(data.toString()),
  child: YourWidget(),
)
```
```dart
// Provider from context
ViewStateListener.of<MyViewStateProvider, MyDataType>(
  dataStateListener: (data) => context.showToast(data.toString()),
  child: YourWidget(),
);
```

| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `provider`                 | `P`                                                                                           | **Required**         | The provider instance to listen to. To resolve the provider from the widget tree, use the `.of` method instead. |
| `initialStateListener`     | `void Function()?`                                                                            | Optional         | Invoked when the state is `InitialState`. |
| `loadingStateListener`     | `void Function(String? message, double? progress)?`                                          | Optional         | Invoked when the state is `LoadingState`. |
| `dataStateListener`        | `void Function(T data)?`                                                                      | **Required**     | Invoked when the state is `DataState`. |
| `emptyStateListener`       | `void Function(String? message)?`                                                             | Optional         | Invoked when the state is `EmptyState`. |
| `errorStateListener` | `void Function(ErrorInfo errorInfo, Object error, StackTrace stackTrace, VoidCallback? onRetry)?` | Optional | Invoked when the state is `ErrorState`. |
| `listenWhen`               | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                   | Optional         | Determines whether to listen for state changes based on previous and next state comparisons. |
| `callListenerOnInit` | `bool`                                                                                        | Optional         | Determines whether the state listener should be called immediately upon initialization. Defaults to `false`. |
| `child`                    | `Widget?`                                                                                    | **Required**     | The child widget wrapped by `ViewStateListener`. |


## ViewStateBuilder
A widget that rebuilds the UI based on the current `ViewState`.

The state widgets configured through [`ViewStateWidgetsProvider`](#viewstatewidgetsprovider)
are used by default for `InitialState`, `LoadingState`, `EmptyState`, and
`ErrorState`. You can override any of them directly in `ViewStateBuilder`.

```dart
// Explicit provider
ViewStateBuilder<MyDataType>(
  provider: myProvider,
  dataBuilder: (data) => Text(data.toString()),
)
```
```dart
// Provider from context
ViewStateBuilder.of<MyViewStateProvider, MyDataType>(
  dataBuilder: (data) => Text(data.toString()),
);
```


| Attribute Name     | Type                                                                 | Required/Optional | Description |
|-------------------|----------------------------------------------------------------------|------------------|-------------|
| `provider`       | `P`                                                                 | **Required**         | The provider instance to listen to. To resolve the provider from the widget tree, use the `.of` method instead. |
| `rebuildWhen`    | `bool Function(ViewState<T> previous, ViewState<T> next)?`           | Optional         | Determines if the builder should rebuild based on state changes. |
| `initialBuilder` | `Widget Function(bool isSliver)?`                                    | Optional         | Called when the state is `InitialState`. |
| `dataBuilder`    | `Widget Function(T data)`                                            | **Required**     | Called when the state is `DataState`, passing the retrieved data. |
| `errorBuilder` | `Widget Function(ErrorInfo errorInfo, Object error, StackTrace stackTrace, VoidCallback? onRetry, bool isSliver)?` | Optional | Called when the state is `ErrorState`. |
| `loadingBuilder` | `Widget Function(String? message, double? progress, bool isSliver)?` | Optional         | Called when the state is `LoadingState`. |
| `emptyBuilder`   | `Widget Function(String? message, bool isSliver)?`                   | Optional         | Called when the state is `EmptyState`. |
| `isSliver`       | `bool`                                                               | Optional         | Specifies whether the widget is a sliver. Defaults to `false`. |
| `child`         | `Widget?`                                                            | Optional         | A static child widget that does not depend on the state. |


## `ViewStateConsumer`

A widget that combines the features of `ViewStateListener` and
`ViewStateBuilder`, allowing you to listen to state changes and rebuild the UI
from the same provider.

The state widgets configured through [`ViewStateWidgetsProvider`](#viewstatewidgetsprovider)
are used by default for `InitialState`, `LoadingState`, `EmptyState`, and
`ErrorState`. You can override them directly in `ViewStateConsumer` when needed.

```dart
// Explicit provider
ViewStateConsumer<MyDataType>(
  provider: myProvider,
  dataStateListener: (data) => context.showToast(data.toString()),
  dataBuilder: (data) => Text(data.toString()),
)
```

```dart
// Provider from context
ViewStateConsumer.of<MyViewStateProvider, MyDataType>(
  dataStateListener: (data) => context.showToast(data.toString()),
  dataBuilder: (data) => Text(data.toString()),
);
```


| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `provider`                 | `P`                                                                                           | **Required**         | The provider instance to listen to. To resolve the provider from the widget tree, use the `.of` method instead. |
| `initialStateListener`     | `void Function()?`                                                                            | Optional         | Invoked when the state is `InitialState`. |
| `loadingStateListener`     | `void Function(String? message, double? progress)?`                                          | Optional         | Invoked when the state is `LoadingState`. |
| `dataStateListener`        | `void Function(T data)?`                                                                      | Optional         | Invoked when the state is `DataState`. |
| `emptyStateListener`       | `void Function(String? message)?`                                                             | Optional         | Invoked when the state is `EmptyState`. |
| `errorStateListener` | `void Function(ErrorInfo errorInfo, Object error, StackTrace stackTrace, VoidCallback? onRetry)?` | Optional | Invoked when the state is `ErrorState`. |
| `listenWhen`               | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                   | Optional         | Determines whether to listen for state changes based on previous and next state comparisons. |
||
| `rebuildWhen`              | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                    | Optional         | Determines if the builder should rebuild based on state changes. |
| `initialBuilder`           | `Widget Function(bool isSliver)?`                                                             | Optional         | Called when the state is `InitialState`. |
| `loadingBuilder`           | `Widget Function(String? message, double? progress, bool isSliver)?`                          | Optional         | Called when the state is `LoadingState`. |
| `emptyBuilder`             | `Widget Function(String? message, bool isSliver)?`                                            | Optional         | Called when the state is `EmptyState`. |
| `dataBuilder`              | `Widget Function(T data)`                                                                     | **Required**     | Called when the state is `DataState`, passing the retrieved data. |
| `errorBuilder` | `Widget Function(ErrorInfo errorInfo, Object error, StackTrace stackTrace, VoidCallback? onRetry, bool isSliver)?` | Optional | Called when the state is `ErrorState`. |
| `isSliver`                 | `bool`                                                                                        | Optional         | Specifies whether the widget is a sliver. Defaults to `false`. |

---

## Multi View State Widgets

Multi View State Widgets allow you to listen to multiple `ViewState` providers
with a single widget.

Unlike the regular View State Widgets, these widgets do not resolve providers
from the widget tree. Instead, you provide a list of providers through the
`providers` parameter.

The providers can have the same state type or different types.

<p>
  <img
    src="https://github.com/user-attachments/assets/2cdc892c-190c-4c7d-b61f-2d181ee63b63"
     width="630"
     height="240"
    alt="Multi View State Widgets Demo"
  />
</p>


The following widgets are available:

- [`MultiViewStateListener`](#multiviewstatelistener) — listens to multiple
  `ViewState` providers and executes state-specific side effects.
- [`MultiViewStateBuilder`](#multiviewstatebuilder) — builds the UI based on the
  combined state of multiple providers.
- [`MultiViewStateConsumer`](#multiviewstateconsumer) — combines listening and
  building for multiple providers.


### How Multi View State Widgets Work

The behavior of **`MultiViewStateBuilder`**, **`MultiViewStateListener`**, and **`MultiViewStateConsumer`** depends on the collective states of the provided `ViewState`s. The highest-priority state in the list determines which **builder** or **listener** is triggered.

### Priority Order of States

#### 1️⃣ **`ErrorState`** (**Highest Priority**)  
   - If **any** provider is in `ErrorState`, the `errorStateListener` (or `errorBuilder`) **will be invoked**.  
   - > The first encountered `ErrorState` data will be passed to the `errorStateListener` or `errorBuilder`.

#### 2️⃣ **`InitialState`**  
   - If no `ErrorState` is found, but **at least one provider** is in `InitialState`, the `initialStateListener` (or `initialBuilder`) **will be invoked**.  

#### 3️⃣ **`LoadingState`**  
   - If **no `ErrorState` or `InitialState` exists**, but **at least one provider** is in `LoadingState`, the `loadingStateListener` (or `loadingBuilder`) **will be invoked**.  
   - > **First encountered `LoadingState` message** will be passed to the `loadingStateListener` or `loadingBuilder`.  
   - > **`progress` will be aggregated** from all `LoadingState`s into a **single combined value**.  

#### 4️⃣ **`EmptyState`**  
   - If none of the above states are present, but **at least one provider** is in `EmptyState`, the `emptyStateListener` (or `emptyBuilder`) **will be invoked**.  
   - > The **first encountered `EmptyState` message** will be passed to the `emptyStateListener` or `emptyBuilder`.

#### 5️⃣ **`DataState<DataType>`** (**Lowest Priority**)  
   - Only If **all** providers are in `DataState`, the `dataStateListener` (or `dataBuilder`) **will be invoked**.  


### Additional Notes
- **First encountered state** applies to all states **except** `DataState`.
- **`LoadingState` progress** is **aggregated** from all active `LoadingState`s into a **single combined value**.
- **Modifying `listenWhen` or `rebuildWhen`**  **overrides** the default priority logic which will result in triggering `listener` or `builder` **whenever any provider's state changes**.

### Handling `EmptyState` in MultiViewState Widgets  

> If some providers have **data** while others return **empty**, triggering `EmptyState` may not be ideal.  

**Solution:** **Avoid using `EmptyState` in the provider logic**. Instead, handle **empty cases manually** inside `dataBuilder`.  

This ensures `EmptyState` won’t be triggered unless **all** providers return an empty state.  


## MultiViewStateListener 

The `MultiViewStateListener` allows listening to multiple `ViewState` providers simultaneously. It merges their states into a unified `ViewState`, enabling centralized state management without manually handling multiple providers.

> Check [How Multi View State Widgets Work](#how-multi-view-state-widgets-work) for more detailed information about how which state is triggered

```dart
MultiViewStateListener<MyDataType>(
  providers: [viewStateProviderOne, viewStateProviderTwo, viewStateProviderThree],
  dataStateListener: (dataStates) {
    print(dataStates);
  },
  child: YourChild(),
);
```

`MultiViewStateListener` uses the same parameters as [`ViewStateListener`](#viewstatelistener), but accepts a `providers` list and does not provide an `.of` method.


## MultiViewStateBuilder

`MultiViewStateBuilder` enables building UI based on multiple `ViewState`
providers simultaneously. It combines their states into a unified `ViewState`.

The state widgets configured through
[`ViewStateWidgetsProvider`](#viewstatewidgetsprovider) are used by default for
`InitialState`, `LoadingState`, `EmptyState`, and `ErrorState`. You can override
any of them directly in `MultiViewStateBuilder`.

```dart
MultiViewStateBuilder<MyDataType>(
  providers: [viewStateProviderOne, viewStateProviderTwo, viewStateProviderThree],
  dataBuilder: (dataStates) {
    return YourWidget(dataStates);
  },
);
```

`MultiViewStateBuilder` uses the same parameters as [`ViewStateBuilder`](#viewstatebuilder), but accepts a `providers` list and does not provide an `.of` method.

## MultiViewStateConsumer
`MultiViewStateConsumer` combines the features of
[`MultiViewStateListener`](#multiviewstatelistener) and
[`MultiViewStateBuilder`](#multiviewstatebuilder), allowing you to listen to and
build from multiple `ViewState` providers.

The state widgets configured through
[`ViewStateWidgetsProvider`](#viewstatewidgetsprovider) are used by default for
`InitialState`, `LoadingState`, `EmptyState`, and `ErrorState`. You can override
any of them directly in `MultiViewStateConsumer`.

```dart
MultiViewStateConsumer<MyDataType>(
  providers: [viewStateProviderOne, viewStateProviderTwo, viewStateProviderThree],
  dataStateListener: (dataStates) {
    print(dataStates);
  },
  dataBuilder: (dataStates) {
    return YourWidget(dataStates);
  },
);
```

`MultiViewStateConsumer` uses the same parameters as [`ViewStateConsumer`](#viewstateconsumer), but accepts a `providers` list and does not provide an `.of` method.

---

## Cache Mixins
ProviderKit provides cache mixins for storing and restoring `ViewState` data
when needed.

### ExViewStateCacheMixin

`ExViewStateCacheMixin` can be used with providers that support `ViewState`, such
as [`ViewStateNotifier`](#viewstatenotifier) and
[`AsyncViewStateNotifier`](#asyncviewstatenotifier).

It keeps track of the most recent state of each `ViewState` type and provides
access to the cached states.

#### Features

- Stores the last known state for each `ViewState` type.
- Provides access to cached states through getters.
- Clears cached states when the provider is disposed.

```dart
class MyViewStateProvider extends ViewStateNotifier<MyDataType> with ExViewStateCacheMixin {
  // Your implementation here
}
```


| Name             | Type                  | Description |
|----------------------|----------------------|-------------|
| `exInitialState`    | `InitialState<T>?`   | Stores the last `InitialState`. |
| `exLoadingState`    | `LoadingState<T>?`   | Stores the last `LoadingState`. |
| `exEmptyState`      | `EmptyState<T>?`     | Stores the last `EmptyState`. |
| `exErrorState`      | `ErrorState<T>?`     | Stores the last `ErrorState`. |
| `exDataState`       | `DataState<T>?`      | Stores the last `DataState`. |
| `exDataStateObject` | `T?`                 | Stores the last data object from `DataState`. |
| `clearCache()` | `void`     | Clears all cached states. |


### DataStateCopyCacheMixin

`DataStateCopyCacheMixin` can be used with providers that support `ViewState`,
such as [`ViewStateNotifier`](#viewstatenotifier) and
[`AsyncViewStateNotifier`](#asyncviewstatenotifier).

It allows you to save a copy of the current `DataState` so the original data
can be restored later.

This is useful when temporarily modifying data locally, such as applying a
filter, and then restoring the original data when the filter is removed.

#### Features:
- Stores the latest `DataState<T>` when `saveDataStateCopy()` is called.
- Provides access to the cached `DataState<T>` and its data object.
- Allows the cached data to be restored when needed.
- Clears the cached state through `clearDataStateCopy()`.

```dart
class MyViewStateProvider extends AsyncViewStateNotifier<List<String>> with DataStateCopyCacheMixin {
  void updateDataState(List<String> newData) {
    final newState = DataState(newData);
    saveDataStateCopy(newState);
    state = newState;
  }

  void clearFilter(){
    state = dataStateCopy!; 
  }
}
```


| Name                 | Type                         | Description |
|----------------------|----------------------------------|-------------|
| `dataStateCopy`      | `DataState<T>?`                 | Returns the copy of the saved `DataState<T>`. |
| `dataObjectCopy`     | `T?`                            | Returns the copy of the saved data object from `DataState<T>`. |
| `saveDataStateCopy`  | `(ViewState<T>? newDataState)`  | Saves the given `DataState<T>` and its associated data. |
| `clearDataStateCopy` | `void`                            | Clears the stored `DataState<T>` and its associated data. |

---
<br>

# Mutations

A `Mutation` manages the state of an asynchronous operation such as creating, updating, deleting, or submitting data.
When an operation is running, the UI may need to show a loading indicator, display the result when it succeeds, or show an error when it fails.

`Mutation` handles these states for you, making it simple for the UI to react to the progress and result of an operation.

<p>
  <img
    src="https://github.com/user-attachments/assets/4a715400-0477-4567-988d-3e16d8e299b4"
    width="400"
    alt="Mutation demo"
  />
</p>

## MutationState

A mutation progresses through four states: `MutationIdle` → `MutationLoading` → `MutationSuccess` or `MutationError`.

| State | Description | Properties |
| --- | --- | --- |
| `MutationIdle` | Represents the initial state before the mutation has been executed. | None |
| `MutationLoading` | Represents a mutation that is currently executing. | None |
| `MutationSuccess` | Represents a successfully completed mutation and contains its result. | `data: T` |
| `MutationError` | Represents a failed mutation and contains the mapped `errorInfo`, original `error`, and its `stackTrace`. | `errorInfo: ErrorInfo`, `error: Object`, `stackTrace: StackTrace` |

Mutation state is managed internally by `run()` and cannot be assigned
directly.

When an operation fails, `MutationError` creates `errorInfo` using the
`ErrorInfoMapper` configured through `ProviderKit.configure()`.

`MutationState` provides `when()`, `maybeWhen()`, `whenOrNull()`, `map()`,
`maybeMap()`, and `mapOrNull()` for handling its states.

Use `when()` when every state should be handled:

```dart
state.when(
  idle: () => const Text('Ready'),
  loading: () => const CircularProgressIndicator(),
  success: (data) => Text('Success: $data'),
  error: (errorInfo, error, stackTrace) => Text(errorInfo.message),
);
```


### Defining a Mutation

Create a mutation with the generic type representing the return type of the operation:

```dart
final addTodo = Mutation<Todo>();
```

### Listening to a Mutation

Once a mutation is defined, you can listen to its state in the UI using
ProviderKit state widgets such as [`StateBuilder`](#statebuilder),
[`StateListener`](#statelistener), [`StateConsumer`](#stateconsumer), and their
multi-provider variants.

```dart
StateBuilder(
  provider: deleteTodo,
  builder: (context, state, child) {
    return state.when(
      idle: () => const Text('Delete'),
      loading: () => const CircularProgressIndicator(),
      success: (_) => const Icon(Icons.check),
      error: (errorInfo, error, stackTrace) => Text(errorInfo.message),
    );
  },
);
```
Use [`StateListener`](#statelistener) when you need to perform side effects
without rebuilding the UI.

### Triggering a Mutation

Execute a mutation by passing an asynchronous operation to `run()`:

```dart
await addTodo.run(
  () => Api.addTodo(todo),
);
```

A mutation can be triggered from any application action, such as a button press:

```dart
ElevatedButton(
  onPressed: () async {
    await addTodo.run(
      () => Api.addTodo(todo),
    );
  },
  child: const Text('Add Todo'),
);
```

When `run()` starts, the mutation enters `MutationLoading`. When the operation
completes, it transitions to `MutationSuccess` or `MutationError` depending on
the result.

> **Note:** Multiple `run()` calls can execute concurrently. Each operation
> continues until it completes, but only the most recently started execution can
> update the mutation state. Earlier executions cannot overwrite the state
> produced by a newer execution or by `reset()`.

### Using the Result

`run()` returns the result produced by the asynchronous operation, allowing you
to use it immediately:

```dart
final todo = await addTodo.run(
  () => Api.addTodo(todoId),
);

// Add the created todo to the local list.
myList = [...myList, todo]
```

After a successful execution, the result is also available through the
mutation's `data` property:

```dart
if (addTodo.isSuccess) {
  final todo = addTodo.data;

  // Use the result for other application logic.
}
```

Use the value returned by `run()` when you need the result immediately after the
operation. Use `data` when accessing the result from the current successful
mutation state.

### Resetting

`reset()` returns the mutation to `MutationIdle` and invalidates any in-flight
execution, preventing it from updating the mutation state after the reset.

```dart
addTodo.reset();
```

### Disposing

Dispose the mutation when the widget or provider that owns it is disposed.

```dart
addTodo.dispose();
```

A disposed mutation should not be used again.

## MutationGroup

A `MutationGroup` manages multiple independent `Mutation` instances using unique keys.

Each key represents an independent mutation. Requesting a key returns the
`Mutation` associated with that key.

```dart
final deleteTodo = MutationGroup<void>();

final mutation = deleteTodo(todo.id);

await mutation.run(
  () => Api.deleteTodo(todo.id),
);
```

Conceptually, the group manages:

```text
deleteTodo
├── todo 1 → Mutation<void>
├── todo 2 → Mutation<void>
├── todo 3 → Mutation<void>
└── ...
```

Each keyed mutation has its own independent state:

```text
Todo 1 → Loading
Todo 2 → Idle
Todo 3 → Error
```

The key identifies the mutation within a specific `MutationGroup` instance. The group owns the cache and lifecycle of its keyed mutations.

This is particularly useful for lists, where the same operation may need to run independently for many items.

<p>
  <img
    src="https://github.com/user-attachments/assets/06c6d0d3-e764-4b2c-b546-4ed0460cc8fa"
    width="290" height="355"
    alt="Mutation Demo"
  />
</p>

`MutationGroup` automatically disposes keyed mutations when they have no
listeners and are not currently loading. This prevents a large or continuously
scrolling list from retaining a mutation for every item that has been viewed.

### Defining a MutationGroup

Create a `MutationGroup` with the generic type representing the return type of the operation:

```dart
final deleteTodo = MutationGroup<void>();
```

The group is typically kept inside a provider or other object that owns the
operation:

```dart
class TodoProvider {
  final deleteTodo = MutationGroup<void>();

  Future<void> delete(int id) {
    return deleteTodo(id).run(
      () => Api.deleteTodo(id),
    );
  }

  void dispose() {
    deleteTodo.dispose();
  }
}
```
Dispose the group when the provider that owns it is disposed.

### Getting a Mutation by Key

Call the group with a key to get the mutation associated with that key:

```dart
final mutation = deleteTodo(todo.id);
```

If a mutation for that key is already cached, the same instance is returned:

```dart
final first = deleteTodo(todo.id);
final second = deleteTodo(todo.id);

identical(first, second); // true while cached
```

The cache belongs to the specific `MutationGroup` instance. A different group
has its own independent cache, even when using the same key.

This allows a mutation to remain available when a list item temporarily leaves
the widget tree. When the item appears again, requesting the same key returns
the cached mutation if it has not been disposed.

### Using MutationGroup in a List

A common use case for `MutationGroup` is giving each list item its own
independent mutation state.

```dart
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) {
    final todo = todos[index];
    final mutation = provider.deleteTodo(todo.id);

    return StateBuilder(
      provider: mutation,
      builder: (context, state, child) {
        return ListTile(
          title: Text(todo.title),
          trailing: IconButton(
            onPressed: state.isLoading
                ? null
                : () => provider.delete(todo.id),
            icon: state.isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.delete),
          ),
        );
      },
    );
  },
);
```
### Automatic Disposal

`MutationGroup` automatically disposes a keyed mutation when:

- It has no listeners.
- It is not currently loading.

A mutation remains alive while it has listeners or while its operation is running.

For example:

- `Idle` + no listeners → eligible for disposal
- `Success` + no listeners → eligible for disposal
- `Error` + no listeners → eligible for disposal
- `Loading` + no listeners → kept alive until the operation completes
- Any state + listeners → kept alive

This allows `MutationGroup` to safely manage mutations for large or continuously
scrolling lists without retaining every mutation indefinitely.

### Keeping Completed States Alive

By default, `MutationGroup` can automatically dispose completed mutations when
they have no listeners.

Use `keepAliveStates` to keep specific completed states cached:

```dart
final deleteTodo = MutationGroup<void>(
  keepAliveStates: {
    KeepAliveState.success,
  },
);
```
You can keep both successful and failed mutations alive:

```dart
final deleteTodo = MutationGroup<void>(
  keepAliveStates: {
    KeepAliveState.success,
    KeepAliveState.error,
  },
);
```

`Loading` mutations are always kept alive until their operation completes.

Keeping completed states alive increases the number of mutations retained by the
group, so use it carefully for large or long-lived groups.

### Manual Disposal

You can manually dispose of keyed mutations when you no longer need them.

Use `disposeKey()` to remove and dispose a specific mutation:

```dart
deleteTodo.disposeKey(todo.id);
```

Use `dispose()` to dispose all cached mutations in the group:

```dart
deleteTodo.dispose();
```

Manual disposal immediately disposes the selected mutations, including mutations
that are currently loading.

---

## Automatic Resource Disposal

ProviderKit provides resource mixins that automatically dispose resources
created through them when the owning `ChangeNotifier` or `State` is disposed.

The mixins manage the lifecycle of:

- `Mutation`
- `MutationGroup`
- `Debounce`
- `Throttle`

Resources created through the mixins are owned by their notifier or `State`, so
you do not need to manually dispose each resource.


### NotifierResourcesMixin

Use `NotifierResourcesMixin` with any `ChangeNotifier`, including ProviderKit
notifiers such as `StateNotifier`, `ViewStateNotifier`, and
`AsyncViewStateNotifier`.

```dart
class SearchNotifier extends ChangeNotifier
    with NotifierResourcesMixin {
  late final searchMutation = mutation<List<Movie>>();
  late final searchDebounce = debounce();

  // ...
}
```

Resources are disposed automatically when the notifier is disposed.

### StateResourcesMixin

Use `StateResourcesMixin` with the `State` of a `StatefulWidget`.

```dart
class _SearchPageState extends State<SearchPage>
    with StateResourcesMixin<SearchPage> {
  late final searchMutation = mutation<List<Movie>>();
  late final searchDebounce = debounce();

  // ...
}
```
Resources are disposed automatically when the `State` is disposed.

### Declaring resources

Declare resources with `late final` so they are created lazily when first
accessed and managed automatically by the mixin.

```dart
late final searchMutation = mutation<List<Movie>>();
late final searchGroup = mutationGroup<Movie>();
late final searchDebounce = debounce();
late final searchThrottle = throttle();
```

Use the mixin's resource methods instead of creating `Mutation`, `MutationGroup`,
`Debounce`, or `Throttle` instances directly. Resources created through the
mixin are automatically owned and disposed with the notifier or `State`.

### Shared helpers

For simple debounced or throttled operations, use the shared helpers instead
of creating a dedicated instance:

```dart
debounceRun(() {
  search(query);
});

throttleRun(() {
  submit();
});
```

Each mixin manages one shared `Debounce` and one shared `Throttle`, created
lazily on first use. Calls without a `key` share the same operation, while
different keys maintain independent operations:

```dart
debounceRun(
  () => searchUsers(query),
  key: 'users',
);

debounceRun(
  () => searchMovies(query),
  key: 'movies',
);
```

For complete documentation on `Debounce` and `Throttle`, see
[`rate_kit`](https://pub.dev/packages/rate_kit).

### Automatic disposal

All resources created through these mixins are disposed automatically with
their owner. No manual cleanup is required.

The following is unnecessary:

```dart
// ❌ Not needed.
@override
void dispose() {
  searchMutation.dispose();
  searchDebounce.dispose();
  super.dispose();
}
```

---

## NestedStateListener

`NestedStateListener` allows multiple state listeners to be nested within a
single widget. It supports `StateListener`, `ViewStateListener`,
`MultiStateListener`, and `MultiViewStateListener`.

This is useful when a widget needs to listen to multiple independent state
sources without manually nesting each listener.

```dart
NestedStateListener(
  listeners: [
    StateListener.of<MyProvider, DataType>(
      listener: (context, state) {
        // Handle state changes.
      },
    ),
    MultiStateListener<DataType>(
      providers: [ProviderOne(), ProviderTwo()],
      listener: (context, states) {
        // Handle state changes.
      },
    ),
  ],
  child: const MyChildWidget(),
);
```

---

## NotifierObserver  

`NotifierObserver` allows you to monitor the lifecycle and state changes of
ProviderKit notifiers. It can be used for debugging, logging, analytics, or other cross-cutting
concerns.

### Setting up a global observer

Configure a global `NotifierObserver` through `ProviderKit.configure()`.
This is typically done during application startup, before running the `MaterialApp`.

```dart
void main() {
  ProviderKit.configure(
    observer: MyNotifierObserver(),
  );

  runApp(const MyApp());
}
```
```dart
class MyNotifierObserver extends NotifierObserver {
  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);
    debugPrint('Created: ${notifier.runtimeType}');
  }

  @override
  void onChange(NotifierBase notifier, Change change) {
    super.onChange(notifier, change);
    debugPrint(
      '${notifier.runtimeType}: '
      '${change.currentState.runtimeType} → '
      '${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(
    NotifierBase notifier,
    Object error,
    StackTrace stackTrace,
  ) {
    super.onError(notifier, error, stackTrace);
    debugPrint('${notifier.runtimeType} error: $error');
  }

  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);
    debugPrint('Disposed: ${notifier.runtimeType}');
  }
}
```
---

## VS Code Extension

Speed up ProviderKit development with **ProviderKit Snippets**, a VS Code extension with ready-to-use Dart snippets for common ProviderKit boilerplate.

Type `pk` in a Dart file to discover the available snippets.

[Install VS Code Extension — ProviderKit Snippets](https://marketplace.visualstudio.com/items?itemName=Ram-Prasanth.providerkit-snippets)

---
### Acknowledgements

Some features of this package were inspired by `flutter_bloc` and `riverpod`.

### 🛠 Features & Bug Reports  
Have a feature request or found a bug? Open an issue in the
[GitHub Issue Tracker](https://github.com/RAMb002/provider_kit/issues).

### 🤝 Contributing

Contributions are welcome. You can open an issue or submit a pull request to
improve ProviderKit, fix bugs, add features, or improve the documentation.

Please make sure your changes are tested and follow the existing project
conventions.

### Connect with Me  
Stay updated and reach out for collaborations!  
**Website:** [Ram Prasanth](https://ramprasanth.web.app/)  

[![Buy Me a Coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-3.svg)](https://buymeacoffee.com/ramprasanth)