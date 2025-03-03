**provider_kit** is a state management toolkit for Flutter, built to work seamlessly with the [`provider`](https://pub.dev/packages/provider) package. It simplifies state handling with predefined widgets, reduces boilerplate, and efficiently manages loading, error, and data states. With built-in async support, state observers, caching, and enhanced notifiers.

### Features  

| 🎯 **Feature**                  | 📌 **Description**  |
|----------------------------------|--------------------|
| **🚀Reduces Boilerplate &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**       | Simplifies state management by minimizing repetitive code. |
| **🔄 Handles Multiple States**   | Provides a centralized way to manage loading, error, initial, empty, and data states while supplying predefined widgets for these states to be used within builders. |
| **🎛️ Builders & Listeners**     | Enhanced widgets that integrate automatically with state changes and allow customization. |
| **🔗 Combined Provider States**  | Supports managing multiple provider states together. |
| **💾 State Caching**             | Provides mixins to store and restore state efficiently. |
| **🛠️ Provider Observation**     | Monitors provider lifecycle events for better debugging. |
| **🧩 Immutable Objects**         | Ensures predictable state management through immutability. |
| **⚡ Error & Loading Handling**  | Automatically manages loading and error states with built-in support. |
| **📦 Enhances Provider**         | Extends the functionality of the provider package. |
| **📝 TypeDefs Convention**       | Type definitions use the provider’s name as a prefix for widgets and states, simplifying usage and improving readability. |
<table>
  <tr>
    <th align="center">Before</th>
    <th align="center">After</th>
  </tr>
  <tr valign="top">
    <td><img src="https://github.com/user-attachments/assets/88a771dd-3c0e-482f-9777-a4ad43de6926" alt="Before" width="100%" style="max-height: 400px;"></td>
    <td><img src="https://github.com/user-attachments/assets/238ab060-d432-4b1a-ac9d-1916470de441" alt="After" width="100%" style="max-height: 400px;"></td>
  </tr>
  <tr valign="top">
    <td><img src="https://github.com/user-attachments/assets/63167856-c219-4587-8db9-14f4cd6bbc91" alt="Before" width="100%" style="max-height: 400px;"></td>
    <td><img src="https://github.com/user-attachments/assets/d247e875-0295-446c-8ca0-f4228c2dcb1e" alt="After" width="100%" style="max-height: 400px;"></td>
  </tr>
</table>

---

## Index

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
    - [Provider Kit](#providerkit)
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
- [Nested State Listener](#nestedstatelistener)
- [State Observer](#stateobserver)
- [Templates](#templates)
    - [Vs Code Template Setup](#vs-code-template-setup)
    - [Android Studio and IntelliJ Template Setup](#android-studio-and-intellij-template-setup)
    - [Taking full advantage of templates](#taking-full-advantage-of-templates)
- [Best Practices for Managing Additional State in provider kit](#best-practices-for-managing-additional-state-in-provider-kit)


---

## Getting started

#### Add them to your `pubspec.yaml` file
```yaml
dependencies:
  provider_kit: ^0.0.1
  provider: ^6.1.2  # Replace with the latest version
  ```

Make sure to register your provider to gain full advantage of this package.
```dart
ChangeNotifierProvider(
  create: (_) => MyProvider(),
  child: ...
)
```
For more information and details about registering your provider, see the documentation of [provider](https://pub.dev/packages/provider) package.

Alright, now lets dive in !

## State

State management is simplified using `StateNotifier` and various widgets designed for listening, building, and consuming state changes efficiently.

### StateNotifier

`StateNotifier` acts as the core class of this library, similar to `ValueNotifier` but with enhanced capabilities. By extending `StateNotifier`, our providers become observable, allowing widgets to listen and react to state changes.

```dart
class MyProvider extends StateNotifier<int> {
  CounterProvider() : super(0);

  void increment() => state++;
  void decrement() => state--;
}
```

### _**State Widgets**_

To listen to state changes from our provider, we would use built-in widgets that are designed to interact with the `StateNotifier`. Each widget includes an optional **provider** attribute. By default, state widgets automatically search the widget tree for the corresponding provider type (e.g., `MyProvider`). Alternatively, we can pass a specific provider instance using the **provider** attribute.

- State Widgets includes **`StateListener`, `StateBuilder`, `StateConsumer`**.

### StateListener

A widget that listens for state changes and executes side effects without rebuilding the UI.

```dart
StateListener<MyProvider, MyDataType>(
  provider: provider, // Optional
  listenWhen: (previous, current) => previous != current, // Default, optional
  shouldCallListenerOnInit: false, // Default, optional
  listener: (context, state) {
    // Can execute side effects here
  },
  child: YourWidget(),
);
```

### StateBuilder

A widget in which the builder will be triggered on state change.

```dart
StateBuilder<MyProvider, MyDataType>(
  provider: provider, // Optional
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, state, child) {
    return Text('Count: $state');
  },
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```

### StateConsumer

A widget that combines the features of both `StateListener` and `StateBuilder`.

```dart
StateConsumer<MyProvider, MyDataType>(
  provider: provider,
  listenWhen: (previous, current) => previous != current, // Default, optional
  shouldCallListenerOnInit: false, // Default, optional
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

---


### _**Multi State Widgets**_

With Multi State Widgets, we can listen to multiple providers states with a single widget. However, these widgets won't try to read the provider. 
>**Note:**  Our providers states can either be of the same type or dynamic.

- Multi State Widgets includes **`MultiStateListener`, `MultiStateBuilder` and `MultiStateConsumer`**.

### MultiStateListener

A widget that listens to the state of multiple providers, and a state change in any of the providers will trigger the listener callback.

```dart
MultiStateListener<MyDataType>(
  providers: [provider1, provider2, provider3],
  listenWhen: (previous, current) => previous != current, // Default, optional
  shouldCallListenerOnInit: false, // Default, optional
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
  shouldCallListenerOnInit: false, // Default, optional
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

---

## ViewState

`ViewState` is a sealed class representing different states of a view. It supports various states such as Initial, Loading, Data, Empty, and Error. Each state has specific properties and behaviors.

A Typical use case for `ViewState` is when fetching data asynchronously. For example, it can be from a server or local storage. It can also be used in operation-based scenarios like authentication features.

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

> By default the intial state of `ViewStateNotifier` is LoadingState.

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

**Tired of manually implementing the same logic for every provider?**  
No worries! Introducing **ProviderKit**—a more efficient way to manage our view state.

---

## ProviderKit

`ProviderKit` automates state management, eliminating the need to repeatedly extend `ViewStateNotifier` and implement the same boilerplate logic. It streamlines fetching, handling empty states, error management, and retry mechanisms.

> By default the intial state of `ProviderKit` is LoadingState.

### **How does it work?**

Instead of writing the entire `MyViewStateProvider` which we seen above, we can simply extend `ProviderKit` like this:

```dart
class MyViewStateProvider extends ProviderKit<List<Item>> {

  @override
  FutureOr<List<Item>> fetchData() => Repository().getItems(10);
}

```

**That's it!** 🎉

### **What does `ProviderKit` handle for us?**
✅ Automatically fetches data upon initialization.  
✅ Transitions to `LoadingState` before fetching.  
✅ If the data is `Iterable` and if its empty, it switches to `EmptyState`.  
✅ Catches exceptions and converts them into `ErrorState`.  
✅ Includes a built-in `onRefresh` function, which rebuilds the initialization logic.  
✅ Passes the `onRefresh` function, exception, and stack trace to `ErrorState`.  
 

With `ProviderKit`, state management becomes **cleaner, more efficient, and hassle-free**. 

| **Attributes**         | **Type**                                  | **Description**  |
|-----------------------------|------------------------------------------|----------------|
| **Constructor Params**  |                                          |                |
| `initialState`              | `ViewState<T>`                           | The initial state of the provider. Defaults to `LoadingState`. |
| `disableEmptystate`         | `bool`                                   | By default, if `T` is an `Iterable` (like `List`, `Set`, etc.), an empty iterable will result in `EmptyState`. Setting this to `true` forces an empty iterable to be assigned as `DataState`. |
| **Property**               |                                          |                |
| `state`                     | `ViewState<T>`                           | The current state of the provider, which can be `LoadingState`, `DataState`, `EmptyState`, or `ErrorState`. |
| **Methods**                  |                                          |                |
| `init()`                     | `FutureOr<void>`                         | Runs on initialization, setting up states and **Guared with Try catch**. It won't execute again if already initialized unless `refresh` is called. |
| `fetchData()`                | `FutureOr<T>`                            | Fetches data from an API or database. Must be implemented in subclasses. |
| `errorStateObject()`         | `ErrorState<T>`                          | Helps to customize default `ErrorState` Object |
| `loadingStateObject()`       | `LoadingState<T>`                        | Helps to customize default `LoadingState` Object  |
| `emptyStateObject()`         | `EmptyState<T>`                          | Helps to customize default `EmptyStaet` Object  instance. |
| `refresh()`                  | `Future<void>`                           | Refreshes the provider which will call `init` with `fetchData()` again. |


**Lets customize our `MyViewStateProvider` to the fullest.**

```dart
class MyViewStateProvider extends ProviderKit<List<Item>> {
  // by default `initialState` is `LoadingState`.
  // by default `disableEmptystate` is false.
  MyViewStateProvider()
      : super(initialState: const InitialState(),
      //disabling empty state will set the state to `DataState` instead of `EmptyState`
       disableEmptystate: true);

  @override
  FutureOr<void> init() async {
    // `init` is internally guarded
    // Custom initialization logic goes here

    state = const LoadingState();
    List<Item> items = await fetchData();

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
> **Note:** Even if `refresh` is not passed inside the `ErrorState` for `retry` mechanism, the `refresh` will be automatically be read by the `View State Widgets` as long as the provider extends `ProviderKit`.
---

## ViewStateWidgetsProvider

In a typical application, most screens fetch data from a server or local storage. On every view screen, we compare the state and display the appropriate widget based on that state. For example:  

- `LoadingWidget` when the state is **loading**  
- `ErrorWidget` when the state is **error**  
- `EmptyWidget` when the data list is **empty**  
- `DataWidget` when the data is **successfully fetched**  

Instead of checking the state type and passing the respective widgets for every single screen, we can reuse the same widgets across all screens. We can streamline this process by wrapping our `MaterialApp` with `ViewStateWidgetsProvider` and supplying custom widgets for each state.



>**Note:** These widgets will be used internally by _`ViewStateBuilder`,`ViewStateConsumer`,`MultiViewStateBuilder` and `MultiViewStateConsumer`_ which we’ll explore soon below.  

Additionally, we can wrap a specific part of the widget tree with `ViewStateWidgetsProvider` to override the state widgets for that section.  

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
> **Note:** In `errorStateBuilder`, the `errorMessage`, `onRetry`, `exception`, and `stackTrace` are automatically passed to the function if your provider is `providerKit`.



---

### View State Widgets

These widgets are similar to [State Widgets](#state-widgets) but are designed to adapt based on the corresponding `ViewState`. They listen to a provider that extends either `ViewStateNotifier` or `ProviderKit`, ensuring they respond dynamically to state changes.For example `MyViewStateProvider` which we learned above.

- View State Widgets includes **`ViewStateListener`, `ViewStateBuilder`, `ViewStateConsumer`**.


### ViewStateListener
This widget provides individual `listener` callbacks for each `ViewState`, allowing customized behavior based on the current state.

```dart
ViewStateListener<MyViewStateProvider, MyDataType(
  dataStateListener: (data) => context.showToast(data.toString()),
  child: YourWidget(),
)
```

| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `provider`                 | `P?`                                                                                           | Optional         | Automatically searches the widget tree for the corresponding provider type (e.g., `MyViewStateProvider`) if not provided. |
| `initialStateListener`     | `void Function()?`                                                                            | Optional         | Invoked when the state is `InitialState`. |
| `loadingStateListener`     | `void Function(String? message, double? progress)?`                                          | Optional         | Invoked when the state is `LoadingState`. |
| `dataStateListener`        | `void Function(T data)?`                                                                      | **Required**     | Invoked when the state is `DataState`. |
| `emptyStateListener`       | `void Function(String? message)?`                                                             | Optional         | Invoked when the state is `EmptyState`. |
| `errorStateListener`       | `void Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace)?` | Optional | Invoked when the state is `ErrorState`. |
| `listenWhen`               | `bool Function(ViewState<T> previous, ViewState<T> next)?`                                   | Optional         | Determines whether to listen for state changes based on previous and next state comparisons. |
| `shouldCallListenerOnInit` | `bool`                                                                                        | Optional         | Determines whether the state listener should be called immediately upon initialization. Defaults to `false`. |
| `child`                    | `Widget?`                                                                                    | **Required**     | The child widget wrapped by `ViewStateListener`. |


Each callback is triggered based on the current `ViewState`, allowing dynamic response handling within `ViewStateListener`.

### ViewStateBuilder
This widget provides individual `builder` for each `ViewState`, allowing customized behavior based on the current state. 
 >**Important Note:** _`initialStateBuilder`, `loadingStateBuilder`, `emptyStateBuilder` and `errorStateBuilder` that we supplied to **`ViewStateWidgetsProvider`** will be used by this widget internally by default_.


```dart
ViewStateBuilder<MyViewStateProvider, MyDataType>(
  // Other ViewState builders will be assigned from the `ViewStateWidgetsProvider`.
  // We can override them here in `ViewStateBuilder` if needed.
  // loadingBuilder: (message, progress, isSliver) => ,
  dataBuilder: (data) => Text(data.toString()),
)
```

The `ViewStateBuilder` allows customization of UI rendering for different `ViewState`s, enabling dynamic UI updates based on the current state.

| Attribute Name     | Type                                                                 | Required/Optional | Description |
|-------------------|----------------------------------------------------------------------|------------------|-------------|
| `provider`       | `P?`                                                                 | Optional         | Automatically searches the widget tree for the corresponding provider type if not provided. |
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
ViewStateConsumer<MyViewStateProvider, MyDataType(
  dataStateListener: (data) {
    print(data);
  },
  dataBuilder: (data) => Text(data.toString()),
)
```


| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `provider`                 | `P?`                                                                                           | Optional         | Automatically searches the widget tree for the corresponding provider type. |
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

Multi View State Widgets allow us to listen to multiple providers' `ViewState`s with a single widget. However, **these widgets do not read the provider**. 
>**Note:**  Our providers states can either be of the same types or dynamic.

> **Key Difference:** Unlike `ViewStateListener`, `ViewStateBuilder`, and `ViewStateConsumer`, Multi View State Widgets require a **list of providers** as a mandatory attribute.

- Multi View State Widgets inlcudes **`MultiViewStateListener`, `MultiViewStateBuilder` and `MultiViewStateConsumer`**.


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
- **Modifying `listenWhen` or `rebuildWhen`**  **overrides** the default priority logic which will results in triggering `listener` or `builder` **whenever any provider's state changes**.

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

| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `providers`                | `List<ViewStateNotifier<T>>`                                                                 | **Required**     | A list of `ViewStateNotifier` providers that the listener will observe. |
| `initialStateListener`     | `void Function()?`                                                                            | Optional         | Callback triggered when the state transitions to `InitialState`. |
| `loadingStateListener`     | `void Function(String? message, double? progress)?`                                          | Optional         | Invoked when the state is `LoadingState`. Receives a message and an aggregated progress value (if multiple providers are loading). |
| `emptyStateListener`       | `void Function(String? message)?`                                                             | Optional         | Triggered when the state is `EmptyState`. Uses the first encountered `EmptyState`'s empty message. |
| `errorStateListener`       | `void Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace)?` | Optional | Called when the state transitions to `ErrorState`, passing the first encountered error details. |
| `dataStateListener`        | `void Function(List<DataState<T>> dataStates)?`                                                 | Optional     | Called when all providers transition to `DataState`, providing the combined list of data states. |
| `listenWhen`               | `bool Function(List<ViewState<T>> previous, List<ViewState<T>> next)`                        | Optional         | Modifying this **overrides** the default priority logic, triggering  `listener` whenever any provider's state changes |
| `shouldCallListenerOnInit` | `bool`                                                                                        | Optional         | Determines whether the listener should be triggered immediately when the widget initializes. Defaults to `false`. |
| `child`                    | `Widget?`                                                                                    | **Required**     | The wrapped widget that remains within the listener, receiving state updates. |


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

| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `providers`                | `List<ViewStateNotifier<T>>`                                                                 | **Required**     | A list of `ViewStateNotifier` providers that the builder will observe. |
| `initialBuilder`           | `Widget Function(bool isSliver)?`                                                              | Optional         | Builder triggered when the state transitions to `InitialState`. |
| `loadingBuilder`           | `Widget Function(String? message, double? progress, bool isSliver)?`                           | Optional         | Triggered when the state is `LoadingState`. Receives a message and an aggregated progress value (if multiple providers are loading).|
| `emptyBuilder`             | `Widget Function(String? message, bool isSliver)?`                                             | Optional         | Triggered when the state is `EmptyState`. Uses the first encountered `EmptyState`'s empty message. |
| `errorBuilder`             | `Widget Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace, bool isSliver)?` | Optional | Triggered when the state transitions to `ErrorState`, passing the first encountered error details. |
| `dataBuilder`              | `Widget Function(List<DataState<T>> dataStates)?`                                              | **Required**     | Triggered when all providers transition to `DataState`, providing the combined list of data states. |
| `rebuildWhen`              | `bool Function(List<ViewState<T>> previous, List<ViewState<T>> next)?`                        | Optional         | Modifying this **overrides** the default priority logic, triggering  `builder` whenever any provider's state changes.  |
| `isSliver`                 | `bool?`                                                                                        | Optional         | Determines whether the widget should be a `Sliver` or a regular widget. Defaults to `false`. |


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
| Attribute Name              | Type                                                                                           | Required/Optional | Description |
|----------------------------|------------------------------------------------------------------------------------------------|------------------|-------------|
| `providers`                | `List<ViewStateNotifier<T>>`                                                                 | **Required**     | A list of `ViewStateNotifier` providers that the consumer will observe. |
| `initialStateListener`     | `void Function()?`                                                                            | Optional         | Callback triggered when the state transitions to `InitialState`. |
| `loadingStateListener`     | `void Function(String? message, double? progress)?`                                          | Optional         | Invoked when the state is `LoadingState`. Receives a message and an aggregated progress value (if multiple providers are loading). |
| `emptyStateListener`       | `void Function(String? message)?`                                                             | Optional         | Triggered when the state is `EmptyState`. Uses the first encountered `EmptyState`'s empty message. |
| `errorStateListener`       | `void Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace)?` | Optional | Called when the state transitions to `ErrorState`, passing the first encountered error details. |
| `dataStateListener`        | `void Function(List<DataState<T>> dataStates)?`                                               | Optional         | Called when all providers transition to `DataState`, providing the combined list of data states. |
| `listenWhen`               | `bool Function(List<ViewState<T>> previous, List<ViewState<T>> next)`                        | Optional         | Modifying this **overrides** the default priority logic, triggering `listener` whenever any provider's state changes. |
| `shouldCallListenerOnInit` | `bool`                                                                                        | Optional         | Determines whether the listener should be triggered immediately when the widget initializes. Defaults to `false`. |
| `initialBuilder`           | `Widget Function(bool isSliver)?`                                                              | Optional         | Builder triggered when the state transitions to `InitialState`. |
| `loadingBuilder`           | `Widget Function(String? message, double? progress, bool isSliver)?`                           | Optional         | Triggered when the state is `LoadingState`. Receives a message and an aggregated progress value (if multiple providers are loading). |
| `emptyBuilder`             | `Widget Function(String? message, bool isSliver)?`                                             | Optional         | Triggered when the state is `EmptyState`. Uses the first encountered `EmptyState`'s empty message. |
| `errorBuilder`             | `Widget Function(String? message, VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace, bool isSliver)?` | Optional | Triggered when the state transitions to `ErrorState`, passing the first encountered error details. |
| `dataBuilder`              | `Widget Function(List<DataState<T>> dataStates)?`                                              | **Required**     | Triggered when all providers transition to `DataState`, providing the combined list of data states. |
| `rebuildWhen`              | `bool Function(List<ViewState<T>> previous, List<ViewState<T>> next)?`                        | Optional         | Modifying this **overrides** the default priority logic, triggering `builder` whenever any provider's state changes. |
| `isSliver`                 | `bool?`                                                                                        | Optional         | Determines whether the widget should be a `Sliver` or a regular widget. Defaults to `false`. |

---

## Cache Mixins
Some mixins to help with `ViewState` caching and data caching that will come handy.

### ExViewStateCacheMixin

This mixin can be used on provider with `ViewState` support like `ViewStateNotifier` or `ProviderKit`. It provides caching capabilities for different view states. It keeps track of the most recent state of each type and allows easy retrieval of cached states.

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

This mixin can be used on provider with `ViewState` support like `ViewStateNotifier` or `ProviderKit`. We can use this mixin to cache original data.
> sometimes we do local filtering on data we fetched from server and when user cancel filter we need to show the original data back which is exactly when we should use this mixin.

#### Features:
- Stores the latest `DataState<T>` and data when `saveDataStateCopy` is called.
- Provides access to the cached `DataState<T>` and its data object.
- Allows clearing cached state manually using `clearDataStateCopy`.

```dart
class MyViewStateProvider extends ProviderKit<List<String>> with DataStateCopyCacheMixin {
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

## NestedStateListener

`NestedStateListener` is a widget that nests multiple state listeners within a single widget. It allows you to combine different types of listeners and manage them together efficiently.

- Supports nesting multiple state listeners.
- Works seamlessly with `StateListener`, `ViewStateListener`, `MultiStateListener`, and `MultiViewStateListener`.
- Reduces boilerplate code by combining multiple listeners into a single widget.


```dart
NestedStateListener(
      listeners: [
        StateListener<MyProvider,DataType>(
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
        ViewStateListener<MyProvider,DataType(
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

## StateObserver  

The `StateObserver` helps in monitoring provider activites. It can be used for debugging, for example - by logging lifecycle events such as creation, state changes, errors, and disposal.  

```dart
void main() {
  // Set the state observer
  StateNotifier.observer = NotifierLogger();
  runApp(const MyApp());
}

class MyStateObserver extends StateObserver {
  @override
  void onChange(StateNotifierBase stateNotifier, Change change) {
    super.onChange(stateNotifier, change);
    debugPrint(
      'StateNotifier onChange -- \${stateNotifier.runtimeType}, '
      '\${change.currentState.runtimeType} ---> \${change.nextState.runtimeType}',
    );
  }

  @override
  void onCreate(StateNotifierBase stateNotifier) {
    super.onCreate(stateNotifier);
    debugPrint('StateNotifier onCreate -- \${stateNotifier.runtimeType}');
  }

  @override
  void onError(
      StateNotifierBase stateNotifier, Object error, StackTrace stackTrace) {
    debugPrint(
      'StateNotifier onError -- \${stateNotifier.runtimeType} '
      'Error: \$error StackTrace: \$stackTrace',
    );
    super.onError(stateNotifier, error, stackTrace);
  }

  @override
  void onDispose(StateNotifierBase stateNotifier) {
    super.onDispose(stateNotifier);
    debugPrint('StateNotifier onDispose -- \${stateNotifier.runtimeType}');
  }
}
```

---

# **Templates**

This guide provides step-by-step instructions for setting up the **ProviderKit Template** in **VS Code** and **Android Studio/IntelliJ** on both **Mac & Windows**.


## **VS Code Template Setup**  

### 🔹 **Step 1: Open Snippets File**
1. Open **VS Code**.
2. Press **`Cmd + Shift + P`** (Mac) or **`Ctrl + Shift + P`** (Windows).
3. Type `"Snippets: Configure Snippets"` and select it.
4. Choose **`dart.json`** to open the Dart snippets file.

### 🔹 **Step 2: Add ProviderKit Snippet**
1. Copy the following snippet:

   ```json
   {
     "ProviderKit Template": {
       "prefix": "pkit",
       "description": "ProviderKit template for view state provider",
       "body": [
         "import 'dart:async';",
         "",
         "import 'package:provider_kit/provider_kit.dart';",
         "",
         "class ${1:ProviderName}Provider extends ProviderKit<${2:DataType}> {",
         "",
         "  @override",
         "  FutureOr<${2:DataType}> fetchData() async {",
         "    return ;",
         "  }",
         "",
         "}",
         "",
         "typedef ${1:ProviderName}ViewState = ViewState<${2:DataType}>;",
         "",
         "typedef ${1:ProviderName}InitialState = InitialState<${2:DataType}>;",
         "typedef ${1:ProviderName}LoadingState = LoadingState<${2:DataType}>;",
         "typedef ${1:ProviderName}EmptyState = EmptyState<${2:DataType}>;",
         "typedef ${1:ProviderName}DataState = DataState<${2:DataType}>;",
         "typedef ${1:ProviderName}ErrorState = ErrorState<${2:DataType}>;",
         "",
         "typedef ${1:ProviderName}ViewStateBuilder = ViewStateBuilder<${1:ProviderName}Provider, ${2:DataType}>;",
         "typedef ${1:ProviderName}ViewStateListener = ViewStateListener<${1:ProviderName}Provider, ${2:DataType}>;",
         "typedef ${1:ProviderName}ViewStateConsumer = ViewStateConsumer<${1:ProviderName}Provider, ${2:DataType}>;"
       ]
     }
   }
   ```

2. Paste it inside `dart.json`.
3. Save the file (**Cmd + S** on Mac, **Ctrl + S** on Windows).

### 🔹 **Step 3: Verify Snippet**
1. Open any Dart file.
2. Type `"pkit"` and press **`Tab`** to insert the template.

### **Important Note for VS Code Users**  

- **Pressing `Tab` should move the cursor to the next snippet placeholder** (e.g., from `ProviderName` to `DataType`).  
- If `Tab` **does not move to the next placeholder**, follow these troubleshooting steps:

  ####  **Troubleshooting Steps**
  1. **Check your settings**:  
     - Open **VS Code Settings** (`Ctrl + ,` or `Cmd + ,`).
     - Search for `"Tab Completion"` and set it to **`onlySnippets`**.
  
  2. **Restart VS Code** after changing the setting.
  
  3. **Disable conflicting extensions**:  
     - If you have **Tabnine VS Code extension**, try disabling it.  
     - Some AI-powered extensions override `Tab` behavior.

## Android Studio and IntelliJ Template Setup

### 🔹 Step 1: Open Live Templates
1. Open **IntelliJ IDEA** or **Android Studio**.
2. Go to **Settings** (`Ctrl + Alt + S` on Windows/Linux, `Cmd + ,` on Mac).
3. Navigate to **Editor → Live Templates**.

### 🔹 Step 2: Create a New Template Group
1. Click on the **+ (Add)** button.
2. Select **Template Group**.
3. Name it **ProviderKit**.
4. Paste the below code after selecting the created group.


```xml
<template name="providerkit" value="import 'dart:async';&#10;&#10;import 'package:provider_kit/provider_kit.dart';&#10;&#10;class $NAME$Provider extends ProviderKit&lt;$DATA_TYPE$&gt; {&#10;&#10;  @override&#10;  FutureOr&lt;$DATA_TYPE$&gt; fetchData() async {&#10;    return ;&#10;  }&#10;}&#10;&#10;typedef $NAME$ViewState = ViewState&lt;$DATA_TYPE$&gt;;&#10;typedef $NAME$InitialState = InitialState&lt;$DATA_TYPE$&gt;;&#10;typedef $NAME$LoadingState = LoadingState&lt;$DATA_TYPE$&gt;;&#10;typedef $NAME$EmptyState = EmptyState&lt;$DATA_TYPE$&gt;;&#10;typedef $NAME$DataState = DataState&lt;$DATA_TYPE$&gt;;&#10;typedef $NAME$ErrorState = ErrorState&lt;$DATA_TYPE$&gt;;&#10;&#10;typedef $NAME$ViewStateBuilder = ViewStateBuilder&lt;$NAME$Provider, $DATA_TYPE$&gt;;&#10;typedef $NAME$ViewStateListener = ViewStateListener&lt;$NAME$Provider, $DATA_TYPE$&gt;;&#10;typedef $NAME$ViewStateConsumer = ViewStateConsumer&lt;$NAME$Provider, $DATA_TYPE$&gt;;" description="ProviderKit template for four-state provider" toReformat="false" toShortenFQNames="true">
  <variable name="NAME" expression="" defaultValue="" alwaysStopAt="true" />
  <variable name="DATA_TYPE" expression="" defaultValue="" alwaysStopAt="true" />
  <context>
    <option name="DART" value="true" />
    <option name="FLUTTER" value="true" />
  </context>
</template>
```

### How to Use the Template
1. Open a Dart file.
2. Type `pkit` and press **Tab** or **Enter**.
3. The template expands, allowing you to fill in `NAME` and `DATA_TYPE`.


## Taking full advantage of templates

### ProviderKit Template

`ProviderKit` provides a structured way to manage view states efficiently. Below is a template that allows you to create a `FeedProvider` using `ProviderKit`.

```dart
import 'dart:async';
import 'package:provider_kit/provider_kit.dart';

class FeedProvider extends ProviderKit<List<Item>> {
  @override
  FutureOr<List<Item>> fetchData() async {
    return []; // Fetch data from an API or database
  }
}

typedef FeedViewState = ViewState<List<Item>>;

typedef FeedInitialState = InitialState<List<Item>>;
typedef FeedLoadingState = LoadingState<List<Item>>;
typedef FeedEmptyState = EmptyState<List<Item>>;
typedef FeedDataState = DataState<List<Item>>;
typedef FeedErrorState = ErrorState<List<Item>>;

typedef FeedViewStateBuilder = ViewStateBuilder<FeedProvider, List<Item>>;
typedef FeedViewStateListener = ViewStateListener<FeedProvider, List<Item>>;
typedef FeedViewStateConsumer = ViewStateConsumer<FeedProvider, List<Item>>;
```

> **Note:** Above `FeedProvider` generated by the template can be used for any [View State Widgets](#view-state-widgets) and [Multi View State Widgets](#multi-view-state-widgets).

### Advantages of Typedefs

Using typedefs in `ProviderKit` offers several advantages:

### 1. Improved Readability
Instead of writing long generic types, typedefs make it easier to understand what each state represents:
```dart
FeedViewState viewState;
```
compared to:
```dart
ViewState<List<Item>> viewState;
```

### 2. Consistency in Naming
By adding `Feed` in front of state widgets, it's easier to identify which provider they belong to. Example:
```dart
FeedViewStateBuilder(
  builder: (context, state) {
    // Handle state changes
  },
)
```
instead of:
```dart
ViewStateBuilder<FeedProvider, List<Item>>(
  builder: (context, state) {
    // Handle state changes
  },
)
```

### 3. Reduced Boilerplate
Instead of specifying the provider and data type every time, typedefs allow you to use shorter, meaningful names.

### 4. Type Safety
By defining typedefs, you ensure that the correct data types are used throughout the app, preventing common mistakes.

---

## Best Practices for Managing Additional State in provider kit

Since `provider_kit` is built with `ChangeNotifier` as its base, there are multiple ways to use the provider.  

### 1. Managing State in Providers  
### **Handling Additional State in `provider_kit`**  

When managing state in `provider_kit`, you may need additional parameters like pagination, filters, or metadata alongside your primary data (e.g., `List<Item>`). Here are three structured approaches to handle this efficiently:

---

#### **1. Using Extra Variables in the Same Provider** (❌ Not Recommended)  

Since `provider_kit` extends `ChangeNotifier`, you can declare additional variables inside the provider and update them using `notifyListeners()`. These variables can be listened to via `Selector` in the UI.

```dart
class MyProvider extends ProviderKit<List<Item>> {
  PaginationData? paginationData;
  FilterData? filterData;

  void updatePagination(PaginationData newData) {
    paginationData = newData;
    notifyListeners();
  }
}
```

❌ **Avoid this approach** as it mixes multiple responsibilities within a single provider, making it harder to maintain and test.

---

#### **2. Using Dart Records or a Custom Data Object** (✅ Preferred)  

A better approach is to store all related data inside `DataState`, ensuring clear separation of concerns.

```dart
DataState((
  pagination: PaginationData(),
  filter: FilterData(),
  items: List<Item>(),
));
```

✅ **Advantages:**  
- Keeps all relevant data encapsulated in a single object.  
- Improves maintainability and separation of concerns.  
- Easier to test and manage.

---

#### **3. Using Separate Providers with `ProxyProvider`** (✅ Best Practice)  

A scalable approach is to keep pagination and filter logic in separate providers and link them using `ProxyProvider`.

```dart
class PaginationProvider extends ProviderKit<PaginationData> {}

class FilterProvider extends ProviderKit<FilterData> {}

ProxyProvider<PaginationProvider, MyProvider>(
  update: (_, pagination, myProvider) =>
      myProvider!..updatePagination(pagination.state),
)
```

✅ **Advantages:**  
- Encourages modularity and reusability.  
- Keeps providers focused on a single responsibility.  
- Enhances performance by updating only necessary state.


---

> Few features of this package were inspired from `flutter_bloc` and `flutter_bloc_ease`.

## 🛠 Features & Bug Reports  
Have a feature request or found a bug? Feel free to open an issue on the [GitHub Issue Tracker](https://github.com/RAMb002/provider_kit/issues). Your feedback helps improve **ProviderKit**!  

## 📢 Connect with Me  
Stay updated and reach out for collaborations!  
**Website:** [Ram Prasanth](https://ramprasanth.web.app/)  

[![Buy Me a Coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-3.svg)](https://buymeacoffee.com/ramprasanth)  

