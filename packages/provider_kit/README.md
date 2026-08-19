[![Build](https://github.com/RAMb002/provider_kit/actions/workflows/build.yml/badge.svg)](https://github.com/RAMb002/provider_kit/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/RAMb002/provider_kit/graph/badge.svg)](https://codecov.io/gh/RAMb002/provider_kit)
[![License: BSD 2-Clause](https://img.shields.io/badge/License-BSD%202--Clause-blue.svg)](https://opensource.org/license/bsd-2-clause/)


<p align="center">
  <img src="https://github.com/user-attachments/assets/76d037a7-16b0-4d77-92f0-18fa7d815ba9"
   width="100%"
   alt="ProviderKit"
   style="border-radius: 16px;"
   />
</p>

---

**provider_kit** is a toolkit for Flutter that works seamlessly alongside the [`provider`](https://pub.dev/packages/provider) package. While `provider` handles dependency injection and makes objects available throughout the widget tree, ProviderKit adds reusable building blocks—notifiers, state objects, widgets, mutations, caching, observation, and utilities—to simplify common development patterns.

Instead of repeatedly implementing state-management logic around `ChangeNotifier`, ProviderKit gives you ready-to-use components that reduce boilerplate, save time, and keep your code cleaner and more consistent.

---
<br>

| 🎯 **Feature** | 📌 **Description** |
|---|---|
| **Less Boilerplate** &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   | Reusable components for common development patterns, reducing repetitive code. |
| **Enhanced Notifiers** | Provides specialized notifiers for managing state, async operations, and application logic. |
| **Builders & Listeners** | Widgets that react to state changes and simplify UI updates and side effects. |
| **Multi-State Support** | Combine and react to multiple provider states with a single widget. |
| **Async State Handling** | Handles loading, error, empty, and data states for asynchronous operations. |
| **Mutations** | Provides dedicated mutation handling for executing asynchronous operations and reacting to their loading, success, and error states. |
| **State Caching** | Mixins for storing and restoring state when needed. |
| **Provider Observation** | Observe provider lifecycle and state changes for better visibility and debugging. |
| **Immutable State** | Provides immutable state objects for predictable state handling. |
| **VS Code Snippets** | [ProviderKit Snippets](https://marketplace.visualstudio.com/) provides ready-to-use Dart snippets for common ProviderKit boilerplate. |


---

## Contents

- [Getting started](#getting-started)
- [State](#state)
    - [State Notifier](#statenotifier)
    - [State Widgets](#state-widgets)
      - [State Listener](#statelistener)
      - [State Builder](#statebuilder)
      - [State Consumer](#stateconsumer)
    - [Multi State Widgets](#multi-state-widgets)
      - [Multi State Listener](#multistatelistener)
      - [Multi State Builder](#multistatebuilder)
      - [Multi State Consumer](#multistateconsumer)
- [View State](#viewstate)
    - [View State Notifier](#viewstatenotifier)
    - [Async View State Notifier](#asyncviewstatenotifier)
    - [View State Widgets Provider](#viewstatewidgetsprovider)
    - [View State Widgets](#view-state-widgets)
      - [View State Listener](#viewstatelistener)
      - [View State Builder](#viewstatebuilder)
      - [View State Consumer](#viewstateconsumer)
    - [Multi View State Widgets](#multi-view-state-widgets)
           - [How Multi View State Widgets work](#how-multi-view-state-widgets-work)
      - [Multi View State Listener](#multiviewstatelistener)
      - [Multi View State Builder](#multiviewstatebuilder)
      - [Multi View State Consumer](#multiviewstateconsumer)
    - [Cache Mixins](#cache-mixins)
      - [Ex View State Cache Mixin](#exviewstatecachemixin)
      - [Data State Copy Cache Mixin](#datastatecopycachemixin)
- [Mutations](#mutations)
    - [Defining a Mutation](#defining-a-mutation)
    - [Listening to a Mutation](#listening-to-a-mutation)
    - [Triggering a Mutation](#triggering-a-mutation)
    - [Using the Result](#using-the-result)
    - [Resetting](#resetting)
    - [Disposing](#disposing)
     - [MutationGroup](#mutationgroup)
        - [Defining a MutationGroup](#defining-a-mutationgroup)
        - [Getting a Mutation by Key](#getting-a-mutation-by-key)
        - [Using MutationGroup in a List](#using-mutationgroup-in-a-list)
        - [Automatic Disposal](#automatic-disposal)
        - [Keeping Completed States Alive](#keeping-completed-states-alive)
        - [Manual Disposal](#manual-disposal)
     - [Why Use MutationGroup?](#why-use-mutationgroup)
     - [Mutation vs MutationGroup](#mutation-vs-mutationgroup)
    - [MutationState](#mutationstate)
- [Nested State Listener](#nestedstatelistener)
- [Notifier Observer](#notifierobserver)
- [VS Code Extension](#vs-code-extension)

---

## Getting started

#### Add them to your `pubspec.yaml` file
```yaml
dependencies:
  provider_kit: ^0.2.0
  provider: ^6.1.5 # For dependency injection
  ```
### Using ProviderKit with `provider`

ProviderKit works with the [`provider`](https://pub.dev/packages/provider) package for dependency injection and accessing providers from the widget tree. This integration is optional, and we will explore it more later.

If you register your provider in the widget tree, ProviderKit UI widgets can access it internally:

```dart
//Registering provider
ChangeNotifierProvider(
  create: (_) => MyProvider(),
  child: ...,
)
```
For more information and details about registering your provider, see the documentation of [provider](https://pub.dev/packages/provider) package.

Alright, now let's dive in!

## State

ProviderKit's state management is based on Flutter's `ChangeNotifier` and `Listenable` ecosystem. Its notifiers provide additional functionality for managing state while remaining compatible with the existing `provider` ecosystem.

### StateNotifier

`StateNotifier` is the core notifier provided by this library, similar to Flutter's `ValueNotifier` but with enhanced capabilities. By extending `StateNotifier`, our providers become observable, allowing widgets to listen and react to state changes.

```dart
class MyProvider extends StateNotifier<int> {
  MyProvider() : super(0);

  void increment() => state++;
  void decrement() => state--;
}
```

### _**State Widgets**_

State Widgets help you react to state changes from your provider (e.g., `StateNotifier`) in the UI.

<p>
  <img
    src="https://github.com/user-attachments/assets/e5a1b3d2-6e95-4bcf-aa31-b88a5dd10046"
    width="354"
    height="240"
    alt="State Widgets Demo"
  />
</p>

The following widgets are available:

- **`StateListener`** — listen to state changes.
- **`StateBuilder`** — rebuild the UI based on state changes.
- **`StateConsumer`** — combine listening and rebuilding.

Each widget supports two ways to access the provider:

1. **Explicitly** — pass a provider instance through the `provider` parameter.
2. **From context** — use the static `.of` method to resolve the provider from the widget tree.

> **Note:** For the `.of` method to work, the provider must be registered in the widget tree using `Provider`, `ChangeNotifierProvider`, or a similar widget from the [`provider`](https://pub.dev/packages/provider) package.
### StateListener

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

### StateBuilder

A widget that rebuilds when the state changes.

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

### StateConsumer

A widget that combines the features of both `StateListener` and `StateBuilder`.

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

---


### _**Multi State Widgets**_

With Multi State Widgets, we can listen to the states of multiple providers using a single widget. However, these widgets won't try to read the provider. 
> **Note:** The providers' states can be of the same type or different types (`dynamic`).  
> The providers themselves are not limited to `StateNotifier`; any object implementing `StateValueListenable` can be used.

<p>
  <img
    src="https://github.com/user-attachments/assets/f67ebb34-9435-4c43-9ed1-6c2e93df631a"
    width="338"
    height="270"
    alt="Multi State Widgets Demo"
  />
</p>

- Multi State Widgets include **`MultiStateListener`, `MultiStateBuilder` and `MultiStateConsumer`**.

### MultiStateListener

A widget that listens to the state of multiple providers, and a state change in any of the providers will trigger the listener callback.

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

### MultiStateBuilder

A widget that listens to the state of multiple providers, and a state change in any of the providers will trigger the builder.

```dart
MultiStateBuilder<MyDataType>(
  providers: [provider1, provider2, provider3],
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, states, child) => Text(states.toString()),
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```

### MultiStateConsumer

A widget that combines both the features of `MultiStateListener` and `MultiStateBuilder`.

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
    return Text('Count: $states');
  },
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```

> **Note:** `State Widgets` and `Multi State Widgets` are not limited to `StateNotifier`. They can be used with any notifier from this package, as long as it implements `StateValueListenable`.

---

## ViewState

`ViewState` represents the different states a view can have, including `Initial`, `Loading`, `Data`, `Empty`, and `Error`.

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
| `DataState`     | Represents a successful data state containing the result object. | `dataObject: T` |
| `EmptyState`    | Represents an empty state with an optional message.              | `message: String?` |
| `ErrorState`    | Represents an error state with an optional message and retry callback. | `message: String?`, `onRetry: VoidCallback?`, `exception: dynamic`, `stackTrace: StackTrace?` |

> **Important Note:** `EmptyState` will be used only for `Iterable` data types. For Example when your T is a `List`, `Set` etc.
---

## ViewStateNotifier

`ViewStateNotifier` is a `StateNotifier` that manages `ViewState<T>`. It simplifies state management by handling various states such as **loading, empty, data, and error** for a given data type.

> By default the initial state of `ViewStateNotifier` is LoadingState.

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
    } catch (e, s) {
      state = ErrorState(e.toString(), e, s, onRefresh);
    }
  }

  void onRefresh() {
    state = const LoadingState();
    init();
  }
}
```
> **Note:** Use `mounted` to check whether the notifier is still alive before updating state after asynchronous operations. This prevents "used after disposed" errors.



**Tired of manually implementing the same logic for every provider?**
No worries! Introducing **AsyncViewStateNotifier**—a more efficient way to manage our view state.

---

## AsyncViewStateNotifier

With `AsyncViewStateNotifier`, much of the boilerplate required for asynchronous state handling is handled automatically:

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

`AsyncViewStateNotifier` automates state management, eliminating the need to repeatedly extend `ViewStateNotifier` and implement the same boilerplate logic. It streamlines fetching, handling empty states, error management, and retry mechanisms.

> By default the initial state of `AsyncViewStateNotifier` is LoadingState.

### **How does it work?**

Instead of writing the entire `MyViewStateProvider` that we saw above, we can simply extend `AsyncViewStateNotifier` like this:

```dart
class MyViewStateProvider extends AsyncViewStateNotifier<List<Item>> {

  @override
  FutureOr<List<Item>> fetchData() => Repository().getItems(10);
}

```

**That's it!** 🎉

### **What does `AsyncViewStateNotifier` handle for us?**
✅ Automatically fetches data upon initialization.  
✅ Transitions to `LoadingState` before fetching.  
✅ If the data is `Iterable` and if it's empty, it switches to `EmptyState`.  
✅ Catches exceptions and converts them into `ErrorState`.  
✅ Includes a built-in `onRefresh` function, which rebuilds the initialization logic.  
✅ Passes the `onRefresh` function, exception, and stack trace to `ErrorState`.  
✅ Internally guarded with `mounted` – For safe async state updates.  

> **Note** `FlutterError` exceptions are **re‑thrown** and **not** converted to `ErrorState`. This ensures that fatal programming errors (e.g., assertion failures) are not masked by the UI.

With `AsyncViewStateNotifier`, state management becomes **cleaner, more efficient, and hassle-free**. 

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


**Lets customize our `MyViewStateProvider` to the fullest.**

```dart
class MyViewStateProvider extends AsyncViewStateNotifier<List<Item>> {
  // by default `initialState` is `LoadingState`.
  // by default `disableEmptyState` is false.
  MyViewStateProvider()
      : super(initialState: const InitialState(),
      //disabling empty state will set the state to `DataState` instead of `EmptyState`
       disableEmptyState: true);

  @override
  FutureOr<void> init() async {
    // `init` is internally guarded
    // Custom initialization logic goes here

    state = const LoadingState();
    List<Item> items = await fetchData();

    if (!mounted) return; // Guard against disposal

    // Additional processing, such as filtering, can be done here
    state = DataState(items);
  }

  @override
  FutureOr<List<Item>> fetchData() async {
    // Fetch data from an API or database
    return [];
  }

  ///  **Custom error state handling**
  @override
  ErrorState<List<Item>> errorStateObject(Object error, StackTrace stackTrace) {
    String message = "Something went wrong";

    // Custom error message handling
    if (error is MyException) {
      message = error.message;
    }

    return ErrorState<List<Item>>(message, error, stackTrace, refresh);
  }

  ///  **Custom loading state**
  @override
  LoadingState<List<Item>> loadingStateObject() {
    return const LoadingState<List<Item>>('Data is Loading...');
  }

  ///  **Custom empty state**
  @override
  EmptyState<List<Item>> emptyStateObject() {
    return const EmptyState<List<Item>>('No data available.');
  }

  ///  **Optional refresh override**
  @override
  Future<void> refresh() async {
    // Perform any additional refresh logic if needed
    super.refresh();
  }
}
```
> **Note:** Even if `refresh` is not passed inside the `ErrorState` for `retry` mechanism, the `refresh` will be automatically be read by the `View State Widgets` as long as the provider extends `AsyncViewStateNotifier`.

Before moving on to the widgets that listen to `ViewStateNotifier` and `AsyncViewStateNotifier`, let's first look at `ViewStateWidgetsProvider`, which allows us to define the default widgets used to represent different `ViewState`s.

---

## ViewStateWidgetsProvider

In a typical application, most screens fetch data from a server or local storage. On every view screen, we compare the state and display the appropriate widget based on that state. For example:  

- `LoadingWidget` when the state is **loading**  
- `ErrorWidget` when the state is **error**  
- `EmptyWidget` when the data list is **empty**  
- `DataWidget` when the data is **successfully fetched**  

Instead of checking the state type and passing the respective widgets for every single screen, we can reuse the same widgets across all screens. We can streamline this process by wrapping our `MaterialApp` with `ViewStateWidgetsProvider` and supplying custom widgets for each state.



>**Note:** These widgets will be used internally by _`ViewStateBuilder`,`ViewStateConsumer`,`MultiViewStateBuilder` and `MultiViewStateConsumer`_ which we’ll explore soon below.

`ViewStateWidgetsProvider` is simply an **inherited widget** that provides consistent state based widgets across our app.


```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewStateWidgetsProvider(
      //supply your initial state widget
      initialStateBuilder: (isSliver) {
        const widget = Center(child: Text("Initial State"));
        return isSliver ? const SliverToBoxAdapter(child: widget) : widget;
      },
      //supply your empty state widget
      emptyStateBuilder: (message, isSliver) {
        Widget widget = Center(child: Text(message ?? "No Data Available"));
        return isSliver ?  SliverToBoxAdapter(child: widget) : widget;
      },
      //supply your error state widget
      //onRetry will refresh the provider 
      errorStateBuilder: (errorMessage, onRetry, exception, stackTrace, isSliver) {
        final widget = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage ?? "An error occurred",
                  style: const TextStyle(color: Colors.red)),
              TextButton(
                  onPressed: onRetry, child: const Text("Retry")),
            ],
          ),
        );
        return isSliver ? const SliverToBoxAdapter(child: widget) : widget;
      },
      //supply your loading state widget
      loadingStateBuilder: (message, progress, isSliver) {
        const widget = Center(child: CircularProgressIndicator());
        return isSliver ? const SliverToBoxAdapter(child: widget) : widget;
      },
      child: const MaterialApp(
          //..
          ),
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
> **Note:** In `errorStateBuilder`, the `errorMessage`, `onRetry`, `exception`, and `stackTrace` are automatically passed to the function if your provider is `providerKit`.

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


---

### View State Widgets

These widgets are similar to [State Widgets](#state-widgets) but are designed to adapt based on the corresponding [ViewState](#viewstate). They listen to a provider that extends either `ViewStateNotifier` or `AsyncViewStateNotifier`, ensuring they respond dynamically to state changes. For example `MyViewStateProvider` which we learned above.

Each widget offers **two** ways to access the provider:
1. **Explicitly** – pass a provider instance directly via the `provider` parameter.
2. **From context** – use the static `.of` method.

> **Note:** For the `.of` method to work, the provider must be registered in the widget tree using `Provider`, `ChangeNotifierProvider`, or a similar widget from the [`provider`](https://pub.dev/packages/provider) package.

- View State Widgets include **`ViewStateListener`, `ViewStateBuilder`, `ViewStateConsumer`**.


### ViewStateListener
This widget provides individual `listener` callbacks for each `ViewState`, allowing customized behavior based on the current state.

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
| `errorStateListener`       | `void Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace)?` | Optional | Invoked when the state is `ErrorState`. |
| `listenWhen`               | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                   | Optional         | Determines whether to listen for state changes based on previous and next state comparisons. |
| `callListenerOnInit` | `bool`                                                                                        | Optional         | Determines whether the state listener should be called immediately upon initialization. Defaults to `false`. |
| `child`                    | `Widget?`                                                                                    | **Required**     | The child widget wrapped by `ViewStateListener`. |


Each callback is triggered based on the current `ViewState`, allowing dynamic response handling within `ViewStateListener`.

### ViewStateBuilder
This widget provides individual `builder` for each `ViewState`, allowing customized behavior based on the current state. 
 >**Important Note:** _`initialStateBuilder`, `loadingStateBuilder`, `emptyStateBuilder` and `errorStateBuilder` that we supplied to **`ViewStateWidgetsProvider`** will be used by this widget internally by default_.


```dart
// Explicit provider
ViewStateBuilder<MyDataType>(
  provider: myProvider,
  // Other ViewState builders will be assigned from the `ViewStateWidgetsProvider`.
  // We can override them here in `ViewStateBuilder` if needed.
  // loadingBuilder: (message, progress, isSliver) => ,
  dataBuilder: (data) => Text(data.toString()),
)
```
```dart
// Provider from context
ViewStateBuilder.of<MyViewStateProvider, MyDataType>(
  dataBuilder: (data) => Text(data.toString()),
);
```

The `ViewStateBuilder` allows customization of UI rendering for different `ViewState`s, enabling dynamic UI updates based on the current state.

| Attribute Name     | Type                                                                 | Required/Optional | Description |
|-------------------|----------------------------------------------------------------------|------------------|-------------|
| `provider`       | `P`                                                                 | **Required**         | The provider instance to listen to. To resolve the provider from the widget tree, use the `.of` method instead. |
| `rebuildWhen`    | `bool Function(ViewState<T> previous, ViewState<T> next)?`           | Optional         | Determines if the builder should rebuild based on state changes. |
| `initialBuilder` | `Widget Function(bool isSliver)?`                                    | Optional         | Called when the state is `InitialState`. |
| `dataBuilder`    | `Widget Function(T data)`                                            | **Required**     | Called when the state is `DataState`, passing the retrieved data. |
| `errorBuilder`   | `Widget Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace, bool isSliver)?` | Optional | Called when the state is `ErrorState`. |
| `loadingBuilder` | `Widget Function(String? message, double? progress, bool isSliver)?` | Optional         | Called when the state is `LoadingState`. |
| `emptyBuilder`   | `Widget Function(String? message, bool isSliver)?`                   | Optional         | Called when the state is `EmptyState`. |
| `isSliver`       | `bool`                                                               | Optional         | Specifies whether the widget is a sliver. Defaults to `false`. |
| `child`         | `Widget?`                                                            | Optional         | A static child widget that does not depend on the state. |


### `ViewStateConsumer`  

This widget combines features of both `ViewStateListener` and `ViewStateBuilder`. We can use this widget when we need both listeners and builders functionality.
 >**Important Note:** _`initialStateBuilder`, `loadingStateBuilder`, `emptyStateBuilder` and `errorStateBuilder` that we supplied to **`ViewStateWidgetsProvider`** will be used by this widget internally by default_.

```dart
// Explicit provider
ViewStateConsumer<MyDataType>(
  provider: myProvider,
  dataStateListener: (data) {
    print(data);
  },
  dataBuilder: (data) => Text(data.toString()),
)
```

```dart
// Provider from context
ViewStateConsumer.of<MyViewStateProvider, MyDataType>(
  dataStateListener: (data) => print(data),
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
| `errorStateListener`       | `void Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace)?` | Optional | Invoked when the state is `ErrorState`. |
| `listenWhen`               | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                   | Optional         | Determines whether to listen for state changes based on previous and next state comparisons. |
||
| `rebuildWhen`              | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                    | Optional         | Determines if the builder should rebuild based on state changes. |
| `initialBuilder`           | `Widget Function(bool isSliver)?`                                                             | Optional         | Called when the state is `InitialState`. |
| `loadingBuilder`           | `Widget Function(String? message, double? progress, bool isSliver)?`                          | Optional         | Called when the state is `LoadingState`. |
| `emptyBuilder`             | `Widget Function(String? message, bool isSliver)?`                                            | Optional         | Called when the state is `EmptyState`. |
| `dataBuilder`              | `Widget Function(T data)`                                                                     | **Required**     | Called when the state is `DataState`, passing the retrieved data. |
| `errorBuilder`             | `Widget Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace, bool isSliver)?` | Optional | Called when the state is `ErrorState`. |
| `isSliver`                 | `bool`                                                                                        | Optional         | Specifies whether the widget is a sliver. Defaults to `false`. |

---

## Multi View State Widgets

Multi View State Widgets allow us to listen to multiple providers `ViewState`'s with a single widget. However, **these widgets do not read the provider**. 
>**Note:**  Our providers states can either be of the same types or dynamic.

> **Key Difference:** Unlike `ViewStateListener`, `ViewStateBuilder`, and `ViewStateConsumer`, Multi View State Widgets require a **list of providers** as a mandatory attribute.

<p>
  <img
    src="https://github.com/user-attachments/assets/2cdc892c-190c-4c7d-b61f-2d181ee63b63"
     width="630"
     height="240"
    alt="Multi View State Widgets Demo"
  />
</p>


- Multi View State Widgets include **`MultiViewStateListener`, `MultiViewStateBuilder` and `MultiViewStateConsumer`**.


### How Multi View State Widgets Work

The behavior of **`MultiViewStateBuilder`**, **`MultiViewStateListener`**, and **`MultiViewStateConsumer`** depends on the collective states of the provided `ViewState`s. The highest-priority state in the list determines which **builder** or **listener** is triggered.

### Priority Order of States

#### 1️⃣ **`ErrorState`** (**Highest Priority**)  
   - If **any** provider is in `ErrorState`, the `errorStateListener` (or `errorBuilder`) **will be invoked**.  
   - > The first encountered `ErrorState` data will be passed to the `errorStatelistener` or `errorBuilder`.

#### 2️⃣ **`InitialState`**  
   - If no `ErrorState` is found, but **at least one provider** is in `InitialState`, the `initialStateListener` (or `initialBuilder`) **will be invoked**.  

#### 3️⃣ **`LoadingState`**  
   - If **no `ErrorState` or `InitialState` exists**, but **at least one provider** is in `LoadingState`, the `loadingStateListener` (or `loadingBuilder`) **will be invoked**.  
   - > **First encountered `LoadingState` message** will be passed to the `loadingStatelistener` or `loadingBuilder`.  
   - > **`progress` will be aggregated** from all `LoadingState`s into a **single combined value**.  

#### 4️⃣ **`EmptyState`**  
   - If none of the above states are present, but **at least one provider** is in `EmptyState`, the `emptyStateListener` (or `emptyBuilder`) **will be invoked**.  
   - > The **first encountered `EmptyState` message** will be passed to the `emptyStatelistener` or `emptybuilder`.

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


### MultiViewStateListener 

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


### MultiViewStateBuilder

The `MultiViewStateBuilder` enables building UI based on multiple `ViewState` providers simultaneously. It merges their states into a unified `ViewState`.
 >**Important Note:** _`initialStateBuilder`, `loadingStateBuilder`, `emptyStateBuilder` and `errorStateBuilder` that we supplied to **`ViewStateWidgetsProvider`** will be used by this widget internally by default_.

```dart
MultiViewStateBuilder<MyDataType>(
  providers: [viewStateProviderOne, viewStateProviderTwo, viewStateProviderThree],
  dataBuilder: (dataStates) {
    return YourWidget(dataStates);
  },
);
```

`MultiViewStateBuilder` uses the same parameters as [`ViewStateBuilder`](#viewstatebuilder), but accepts a `providers` list and does not provide an `.of` method.

### MultiViewStateConsumer
Combines the features of `MultiViewStateListener` and `MultiViewStateBuilder` in a single widget.
 >**Important Note:** _`initialStateBuilder`, `loadingStateBuilder`, `emptyStateBuilder` and `errorStateBuilder` that we supplied to **`ViewStateWidgetsProvider`** will be used by this widget internally by default_.

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
Some mixins to help with `ViewState` caching and data caching that will come handy.

### ExViewStateCacheMixin

This mixin can be used on a provider with `ViewState` support like `ViewStateNotifier` or `AsyncViewStateNotifier`. It provides caching capabilities for different view states. It keeps track of the most recent state of each type and allows easy retrieval of cached states.

#### Features
- Stores the last known state for each `ViewState` type.
- Allows accessing cached states via getter methods.
- Clears cached states when disposed to free up memory.

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
| `exDataStateObject` | `T?`                 | Stores the last known data object from `DataState`. |
| `clearCache()` | `void`     | Clears all cached states. |


### DataStateCopyCacheMixin

This mixin can be used on provider with `ViewState` support like `ViewStateNotifier` or `AsyncViewStateNotifier`. We can use this mixin to cache original data.
> sometimes we do local filtering on data we fetched from server and when user cancel filter we need to show the original data back which is exactly when we should use this mixin.

#### Features:
- Stores the latest `DataState<T>` and data when `saveDataStateCopy` is called.
- Provides access to the cached `DataState<T>` and its data object.
- Allows clearing cached state manually using `clearDataStateCopy`.

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
| `dataStateCopy`      | `DataState<T>?`                 | gets the copy of the saved `DataState<T>`. |
| `dataObjectCopy`     | `T?`                            | gets the copy of the saved data object from `DataState<T>`. |
| `saveDataStateCopy`  | `(ViewState<T>? newDataState)`  | Stores the given `DataState<T>` and its associated data. |
| `clearDataStateCopy` | `void`                            | Clears the stored `DataState<T>` and its associated data. |

---
<br>

## Mutations

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

A mutation progresses through four states:

`MutationIdle` → `MutationLoading` → `MutationSuccess` or `MutationError`

### Defining a Mutation

Create a mutation with the generic type representing the return type of the operation:

```dart
// Tracks the state of an operation that returns a Todo.
final addTodo = Mutation<Todo>();
```

> **Note:** Typically, a mutation is kept inside a provider/notifier/controller/view model that owns the operation.

### Listening to a Mutation

Once a mutation is defined, you can listen to its state in the UI using ProviderKit state widgets such as `StateBuilder`, `StateListener`, and `StateConsumer`.

```dart
StateBuilder(
  provider: deleteTodo,
  builder: (context, state, child) {
    return state.when(
      idle: () => const Text('Delete'),
      loading: () => const CircularProgressIndicator(),
      success: (_) => const Icon(Icons.check),
      error: (error, stackTrace) => const Icon(Icons.error),
    );
  },
);
```
>**Note:** You can perform side effects for mutations with `StateListener`

### Triggering a Mutation

Once a mutation is defined and being observed, execute it by passing an asynchronous operation to `run()`:

```dart
await addTodo.run(
  () => Api.addTodo(todo),
);
```

This is commonly triggered by a user interaction:

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

When the operation starts, the mutation enters `MutationLoading`.

When the operation completes:
- If the operation succeeds, the mutation enters `MutationSuccess`.
- If the operation throws an exception, the mutation enters `MutationError`.

The successful result is available through `MutationSuccess`, while `MutationError` contains the original error and its stack trace.

> **Note:** Mutations allow multiple `run()` calls to execute concurrently. Only the most
> recently started execution can update the mutation state. Earlier executions
> still complete normally but cannot overwrite a newer state or a state set by
> `reset()`.

### Using the Result

`run()` returns the result produced by the asynchronous operation, so you can store it in a variable and use it for subsequent application logic:

```dart
final todo = await addTodo.run(
  () => Api.addTodo(todoId),
);

// Add the created todo to the local list.
myList = [...myList, todo]
```

The result is also available through the mutation's `data` property after a successful execution:

```dart
if (addTodo.isSuccess) {
  final todo = addTodo.data;

  // Use the result for other application logic.
}
```

Use the returned value from `run()` when you need the result immediately after the operation. Use `data` when you want to access the result from the current successful mutation state.

### Resetting

Once an operation is completed, you can reset the mutation back to `MutationIdle` by calling `reset()` if needed.

```dart
addTodo.reset();
```

This clears the current success or error state, returns the mutation to its `idle` state, and invalidates any in-flight execution so that it cannot update the mutation state when it completes.

### Disposing

Dispose a mutation when it is no longer needed, typically when the provider, notifier, controller, or view model that owns it is disposed:

```dart
addTodo.dispose();
```

A disposed mutation should not be used again.
The same mutation can be reused for subsequent executions:



See [MutationState](#mutationstate) for state handling and pattern matching.

---

## MutationGroup

A `MutationGroup` manages multiple independent `Mutation` instances using unique keys.

Each key represents one independent instance of the operation. Requesting a key returns the `Mutation` associated with that key:

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

Each keyed mutation has completely independent state:

```text
Todo 1 → Loading
Todo 2 → Idle
Todo 3 → Error
```

The key identifies the mutation within a specific `MutationGroup` instance. The group owns the cache and lifecycle of all mutations created through it.

This is particularly useful for lists, where the same operation may need to run independently for many items.

<p>
  <img
    src="https://github.com/user-attachments/assets/06c6d0d3-e764-4b2c-b546-4ed0460cc8fa"
    width="290" height="355"
    alt="Mutation Demo"
  />
</p>

`MutationGroup` also automatically disposes keyed mutations that are no longer needed. This prevents a large or continuously scrolling list from retaining a mutation for every item the user has ever viewed.

### Defining a MutationGroup

Create a `MutationGroup` with the generic type representing the return type of the operation:

```dart
final deleteTodo = MutationGroup<void>();
```

The group is typically kept inside a provider, controller, view model, or other object that owns the operation:

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

The group should be disposed when its owner is disposed.

### Getting a Mutation by Key

Call the group with a key to get the mutation associated with that key:

```dart
final mutation = deleteTodo(todo.id);
```

If a mutation for that key is already cached, the existing instance is returned:

```dart
final first = deleteTodo(todo.id);
final second = deleteTodo(todo.id);

identical(first, second); // true while cached
```

>**Note:** The cache belongs to that specific `MutationGroup` instance. A different group, even when called with the same key, has its own independent cache.


This is particularly useful for lists. A list item can be removed from the widget tree when it scrolls off-screen while its mutation remains cached in the group.

When the item appears again, requesting the same key from the same group returns the existing mutation if it is still cached.

### Using MutationGroup in a List

A list item can observe the mutation associated with its own key:

```dart
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) {
    final todo = todos[index];

    // Returns the existing mutation for this key if it is cached;
    // otherwise, creates and caches a new mutation.
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

Keyed mutations are automatically removed from the group's cache when they have no listeners, based on their current state.

By default:

```text
No listeners + Idle     → Eligible for auto-dispose
No listeners + Success  → Eligible for auto-dispose
No listeners + Error    → Eligible for auto-dispose
No listeners + Loading  → Keep alive
Has listeners           → Keep alive
```

This prevents the group from retaining every mutation ever created in memory, which is especially important for large or continuously scrolling lists.

A mutation that is currently loading is always kept alive, even when it has no listeners. This allows the operation to finish without losing its state while the widget is temporarily absent from the widget tree.

Once the loading operation finishes, the mutation becomes eligible for automatic disposal again if it has no listeners.

### Keeping Completed States Alive

By default, successful and failed mutations are automatically disposed when they have no listeners.

You can preserve completed states by passing them to `keepAliveStates`:

```dart
final deleteTodo = MutationGroup<void>(
  keepAliveStates: {
    KeepAliveState.success,
  },
);
```
> **Note:** `Loading` is **always** kept alive, regardless of `keepAliveStates`. This ensures that ongoing operations are never cancelled due to automatic disposal.

In this example:

```text
Idle     → Eligible for auto-dispose
Loading  → Keep alive
Success  → Keep alive
Error    → Eligible for auto-dispose
```

To keep both success and error states alive:

```dart
final deleteTodo = MutationGroup<void>(
  keepAliveStates: {
    KeepAliveState.success,
    KeepAliveState.error,
  },
);
```

This can be useful when a completed state should remain available after its widget is temporarily removed from the widget tree.

**Caution:** Be careful when keeping states alive in large or long-lived groups, as cached mutations remain in memory until they are automatically disposed, manually disposed, or the group itself is disposed.

### Manual Disposal

Dispose a single keyed mutation with `disposeKey()`:

```dart
deleteTodo.disposeKey(todo.id);
```

This immediately removes that mutation from the group and disposes it, even if it is currently loading.

To dispose every cached mutation in the group:

```dart
deleteTodo.dispose();
```

This also disposes mutations that are currently loading.

A provider or controller that owns a group should dispose it when the owner is disposed:

```dart
class TodoProvider {
  final deleteTodo = MutationGroup<void>();

  void dispose() {
    deleteTodo.dispose();
  }
}
```
>**Note:** Always dispose the `MutationGroup` when it is no longer needed.


## Why Use MutationGroup?

`MutationGroup` is useful when the same type of operation needs to maintain independent state for multiple entities.

It provides:

- **Independent state** — each key has its own `Mutation` and state.
- **Key-based reuse** — requesting the same key from the same group returns the existing cached mutation while it remains cached.
- **Widget-independent state** — the mutation is owned by the group rather than by the widget displaying the item.
- **Automatic disposal** — unobserved mutations can be removed from the cache automatically, preventing unnecessary memory usage in large lists.
- **Configurable retention** — completed success or error states can be kept alive when needed.
- **Manual control** — individual mutations or the entire group can be disposed explicitly.

## Mutation vs MutationGroup

Use `Mutation` when one operation has one shared state:

```dart
final logout = Mutation<void>();
```

Use `MutationGroup` when the same operation needs independent state for multiple keys:

```dart
final deleteTodo = MutationGroup<void>();

deleteTodo(todo1.id);
deleteTodo(todo2.id);
deleteTodo(todo3.id);
```

| | `Mutation` | `MutationGroup` |
|---|---|---|
| State instances | One | One per key |
| Best for | One shared operation | Independent operations per item |
| Key required | No | Yes |
| Independent states | No | Yes |
| Automatic disposal | No | Yes |
| Manual disposal | `dispose()` | `disposeKey()` / `dispose()` |

>**Note:** Use `MutationGroup` when the operation itself is the same, but each key needs its **own independent mutation state and lifecycle**.

---

## MutationState

`MutationState` represents the different states of a mutation operation, including `Idle`, `Loading`, `Success`, and `Error`.

It is particularly useful for tracking the progress and result of asynchronous operations such as creating, updating, deleting, submitting, logging in, or uploading data.

| State | Description | Properties |
| --- | --- | --- |
| `MutationIdle` | Represents the initial state before the mutation has been executed. | None |
| `MutationLoading` | Represents a mutation that is currently executing. | None |
| `MutationSuccess` | Represents a successfully completed mutation and contains its result. | `data: T` |
| `MutationError` | Represents a failed mutation and contains the error and its stack trace. | `error: Object`, `stackTrace: StackTrace` |

`MutationState` provides pattern-matching helpers for handling its different states. Use `when()` and `maybeWhen()` when you want to work with the values exposed by each state, and `map()` and `maybeMap()` when you need access to the complete state object.

### `when`

Use `when()` when every state should be handled:

```dart
state.when(
  idle: () => const Text('Ready'),
  loading: () => const CircularProgressIndicator(),
  success: (data) => Text('Success: $data'),
  error: (error, stackTrace) => Text('Error: $error'),
);
```

### `maybeWhen`

Use `maybeWhen()` when only specific states need handling:

```dart
state.maybeWhen(
  loading: () => const CircularProgressIndicator(),
  orElse: () => const SizedBox(),
);
```

### `map`

Use `map()` when you need access to the complete state object:

```dart
state.map(
  idle: (state) => const Text('Ready'),
  loading: (state) => const Text('Loading'),
  success: (state) => Text('Result: ${state.data}'),
  error: (state) => Text('Error: ${state.error}'),
);
```

`maybeMap()` can be used when only specific state objects need to be handled.
```dart
state.maybeMap(
  loading: (state) => const CircularProgressIndicator(),
  success: (state) => Text('Result: ${state.data}'),
  orElse: () => const SizedBox(),
);
```

---

## NestedStateListener

`NestedStateListener` is a widget that nests multiple state listeners within a single widget. It allows you to combine different types of listeners and manage them together efficiently.

- Supports nesting multiple state listeners.
- Works seamlessly with `StateListener`, `ViewStateListener`, `MultiStateListener`, and `MultiViewStateListener`.
- Reduces boilerplate code by combining multiple listeners into a single widget.


```dart
NestedStateListener(
      listeners: [
        StateListener.of<MyProvider,DataType>(
          listener: (context, state) {
            // Handle state changes
          },
        ),
        MultiStateListener<DataType>(
          providers: [ProviderOne(),ProviderTwo()],
          listener: (context, states) {
            // Handle state changes
          },
        ),
        ViewStateListener<DataType>(
          provider: MyProvider(),
          dataStateListener: (data) {
            // Handle view state changes
          },
        ),
        MultiViewStateListener<DataType>(
          providers: [ProviderOne(),ProviderTwo()],
          dataStateListener: (states) {
            // Handle state changes
          },
        ),
      ],
      child: MyChildWidget(),
    );
```

| **Attribute** | **Type** | **Description** |
|--------------|---------|----------------|
| `listeners` (*Required*) | `List<SingleChildWidget>` | A list of listeners to be applied. These can include `StateListener`, `ViewStateListener`, `MultiStateListener`, and `MultiViewStateListener`. |
| `child` (*Required*) | `Widget` | The child widget that will be wrapped by the listeners. |


> **Note:** Ensure that the `listeners` list contains at least one listener to avoid an empty nesting.

---

## NotifierObserver  

The `NotifierObserver` helps you monitor the lifecycle of all notifiers in your application.  
It can be used for debugging, logging, analytics, or any other cross‑cutting concern – it receives callbacks whenever a notifier is created, changes state, reports an error, or is disposed.

### Setting up a global observer

Assign an implementation of `NotifierObserver` to the static `observer` field on `NotifierBase`.  
This is typically done at the start of your app, before running the `MaterialApp`.

```dart
void main() {
  // Set the global observer
  NotifierBase.observer = MyNotifierObserver();
  runApp(const MyApp());
}

class MyNotifierObserver extends NotifierObserver {
  @override
  void onChange(NotifierBase notifier, Change change) {
    super.onChange(notifier, change);
    debugPrint(
      'notifier onChange -- \${notifier.runtimeType}, '
      '\${change.currentState.runtimeType} ---> \${change.nextState.runtimeType}',
    );
  }

  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);
    debugPrint('notifier onCreate -- \${notifier.runtimeType}');
  }

  @override
  void onError(
      NotifierBase notifier, Object error, StackTrace stackTrace) {
    debugPrint(
      'notifier onError -- \${notifier.runtimeType} '
      'Error: \$error StackTrace: \$stackTrace',
    );
    super.onError(notifier, error, stackTrace);
  }

  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);
    debugPrint('notifier onDispose -- \${notifier.runtimeType}');
  }
}
```


---

> Few features of this package were inspired by `flutter_bloc`.

## VS Code Extension

Speed up ProviderKit development with **ProviderKit Snippets**, a VS Code extension with ready-to-use Dart snippets for common ProviderKit boilerplate.

Type `pk` in a Dart file to discover the available snippets.

[Install VS Code Extension — ProviderKit Snippets](https://marketplace.visualstudio.com/)

---
### 🛠 Features & Bug Reports  
Have a feature request or found a bug? Feel free to open an issue on the [GitHub Issue Tracker](https://github.com/RAMb002/provider_kit/issues). Your feedback helps improve **ProviderKit**!  

### 🤝 Contributing

Contributions are welcome! If you'd like to improve **ProviderKit**, fix a bug, add a feature, or improve the documentation, feel free to open an issue or submit a pull request.

Please make sure your changes are tested and follow the existing project conventions.

### 🧪 Development
**ProviderKit** is backed by a comprehensive automated test suite covering widgets, state management, listeners, edge cases, and other core package functionality.

### 📢 Connect with Me  
Stay updated and reach out for collaborations!  
**Website:** [Ram Prasanth](https://ramprasanth.web.app/)  

[![Buy Me a Coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-3.svg)](https://buymeacoffee.com/ramprasanth)