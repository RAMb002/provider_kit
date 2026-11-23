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

**ProviderKit** is a Flutter toolkit built on Flutter's `ChangeNotifier` and `Listenable` APIs, providing reusable notifiers, reactive widgets, and lifecycle utilities to help you write less code while keeping your application architecture simple, predictable, and maintainable. It works alongside the [`provider`](https://pub.dev/packages/provider) package for dependency injection and accessing notifiers from the widget tree.

## Features

- **Specialized Notifiers** — Manage simple state, structured view state, futures, and streams with dedicated notifier types.
- **Async Safety** — `FutureNotifier` and `StreamNotifier` protect against outdated asynchronous operations.
- **Reactive Widgets** — Builders, listeners, and consumers for responding to state changes and handling side effects.
- **Multi-State Composition** — Combine multiple independent notifiers into a single typed state without creating additional aggregate notifiers or state classes.
- **Structured View States** — Built-in initial, loading, data, empty, and error states with reusable, customizable UI.
- **Mutations** — Handle user-triggered operations with observable states, execution results, and configurable concurrency.
- **Reactive Fields** — Manage supporting values independently from a notifier's primary state.
- **Error Mapping & Observation** — Centralize error information and monitor notifier lifecycle events and state changes.
- **Automatic Resource Disposal** — Automatically dispose owned resources when their owner is disposed.


## Contents

- [Getting started](#getting-started)
- [State](#state)
  - [State Notifier](#statenotifier)
  - [State Widgets](#state-widgets)
  - [Multi State Widgets](#multi-state-widgets)
- [View State](#viewstate)
  - [View State Notifier](#viewstatenotifier)
  - [Future Notifier](#futurenotifier)
  - [Stream Notifier](#streamnotifier)
  - [Shared Async Notifier Features](#shared-async-notifier-features)
  - [View State Widgets](#view-state-widgets)
  - [View State Widgets Provider](#viewstatewidgetsprovider)
  - [Multi View State Widgets](#multi-view-state-widgets)
  - [Cache Mixins](#cache-mixins)
- [Mutation](#mutation)
  - [MutationGroup](#mutationgroup)
- [State Field](#statefield)
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

ProviderKit works with the [provider](https://pub.dev/packages/provider)
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
see the [provider](https://pub.dev/packages/provider) package documentation.

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

ProviderKit provides three state widgets:

- [`StateBuilder`](#statebuilder) — rebuilds the UI when the state changes.
- [`StateListener`](#statelistener) — listens for state changes and performs side effects.
- [`StateConsumer`](#stateconsumer) — combines listening and rebuilding in one widget.

Each widget supports direct listenable access, context-based resolution
through `.of`, and multiple listenables through `.multi`.

For context-based resolution, expose listenables in the widget tree using
a compatible provider, such as `ChangeNotifierProvider`,
from the [`provider`](https://pub.dev/packages/provider) package.

## StateBuilder

A widget that rebuilds the UI when the notifier's state changes.

**Resolve a listenable from the widget tree using the [provider](https://pub.dev/packages/provider) package:**
```dart
StateBuilder.of<CounterNotifier, int>(
  builder: (context, state, child) => Text('$state'),
);
```

**Pass a listenable directly:**
```dart
StateBuilder(
  listenable: counterNotifier,
  rebuildWhen: (previous, current) => previous != current, // Default, optional
  builder: (context, state, child) {
    return Text('Count: $state');
  },
  child: YourStaticWidget(), // Optional, won't be rebuilt
);
```

## StateListener

A widget that listens for state changes and executes side effects without rebuilding the UI.
```dart
StateListener.of<CounterNotifier, int>(
  listenWhen: (previous, current) => previous != current, // Default, optional
  callListenerOnInit: false, // Default, optional
  listener: (context, state) {
    // Can execute side effects here
  },
  child: YourWidget(),
);

```

## StateConsumer

A widget that combines `StateListener` and `StateBuilder`,
allowing you to listen for state changes and rebuild the UI
from the same listenable.

```dart
StateConsumer.of<CounterNotifier, int>(
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

---

### Multi-State Widgets

The `.multi` constructors let you combine multiple listenables into a single,
type-safe state. They are available on `StateListener`, `StateBuilder`, and
`StateConsumer`.

<p>
  <img
    src="https://github.com/user-attachments/assets/f67ebb34-9435-4c43-9ed1-6c2e93df631a"
    width="338"
    height="270"
    alt="Multi State Widgets Demo"
  />
</p>

#### How it works

Each `.multi` constructor accepts a `listenables` callback. Use `.watch` to
subscribe to the listenable's state. The callback can return any Dart type,
including records, lists, or custom objects.

```dart
StateBuilder.multi(
  listenables: () => (
    user: userNotifier.watch,
    cart: cartNotifier.watch,
  ), // Returns a record
  builder: (context, state, child) {
    return Text('${state.user.name}: ${state.cart.length}');
  },
);
```
#### Using Provider

You can also resolve notifiers from the widget tree inside the
`listenables` callback using `of<T>().watch`.

```dart
StateBuilder.multi(
  listenables: () => (
    user: of<UserNotifier>().watch,
    settings: of<SettingsNotifier>().watch,
  ),
  builder: (context, state, child) {
    return Text('${state.user.name}: ${state.settings.theme}');
  },
);
```

### WatchBuilder

`WatchBuilder` provides a simple way to listen to one or more listenables.
It automatically rebuilds the UI whenever a listenable accessed through
`.watch` inside its builder changes.

```dart
WatchBuilder(
  builder: (context, child) {
    final user = userNotifier.watch; // Stable, locally owned notifier.
    final settings = of<SettingsNotifier>().watch; // Provider-managed notifier.

    return Text('${user.name}: ${settings.theme}');
  },
);
```

> **Important:** When you own a notifier and its instance remains stable,
> passing it directly is perfectly fine. However, when a notifier is supplied
> by the `provider` package and may be replaced, prefer resolving it through
> `.of` or `of<T>().watch`. This allows ProviderKit widgets to follow provider
> updates and listen to the newly supplied notifier, such as when using
> `ProxyProvider`.

---

Now that we've covered the core state-management building blocks, let's move
on to ProviderKit's higher-level features for handling common application
workflows.

## ViewState

`ViewState<T>` represents the different states of data displayed by a view:

- `InitialState` — the initial state of a view.
- `LoadingState` — data is being loaded.
- `DataState<T>` — data has been loaded successfully.
- `EmptyState` — the result contains no data.
- `ErrorState` — an error occurred while loading data.

It is particularly useful for managing data displayed by a view, such as data loaded from a server or local storage, where the UI needs to represent different stages of the data lifecycle.

<p>
  <img
    src="https://github.com/user-attachments/assets/0a8736e6-56c3-4c8d-9774-5a67a9954396"
     width="325.5"
     height="262.5"
    alt="View State Widgets Demo"
  />
</p>

`ViewState<T>` also provides `data` and `dataOrNull` getters to access the data contained in a `DataState`.

### Handling ViewState

`ViewState<T>` provides `when()`, `maybeWhen()`, `whenOrNull()`, `map()`, `maybeMap()`, and `mapOrNull()` to handle its different states without manually checking their types.

Use `when()` to handle every state and access its values:

```dart
state.when(
  initialState: () => ...,
  loadingState: (message, progress) => ...,
  dataState: (data) => ...,
  emptyState: (message, onRefresh) => ...,
  errorState: (errorInfo, error, stackTrace, onRetry) => ...,
);
```

Use `map()` when you need to handle the concrete state objects instead. The `maybe` and `OrNull` variants let you handle only the states you need.

## ViewStateNotifier

`ViewStateNotifier<T>` is a base class for manually managing a `ViewState<T>`. Extend it when you want to control state transitions yourself.

```dart
class ProductsNotifier extends ViewStateNotifier<List<Product>> {
  ProductsNotifier(this._repository) : super(const InitialState());

  final ProductRepository _repository;

  Future<void> loadProducts() async {
    state = const LoadingState();

    try {
      final products = await _repository.fetchProducts();

      if (products.isEmpty) {
        state = const EmptyState();
      } else {
        state = DataState(products);
      }
    } catch (error, stackTrace) {
      state = ErrorState(error, stackTrace);
    }
  }
}
```

For common asynchronous workflows, use `FutureNotifier` or `StreamNotifier`, which manage the corresponding `ViewState` transitions automatically.

## FutureNotifier

`FutureNotifier<T>` manages asynchronous data loading through a `Future`. Override `build()` to provide the data, and ProviderKit automatically manages the corresponding `ViewState` transitions.

```dart
class ProductsNotifier extends FutureNotifier<List<Product>> {
  ProductsNotifier(this._repository);

  final ProductRepository _repository;

  @override
  Future<List<Product>> build() {
    return _repository.fetchProducts();
  }
}
```

## StreamNotifier

`StreamNotifier<T>` manages continuous data updates through a `Stream`. Override `build()` to provide the stream, and ProviderKit manages the subscription and corresponding `ViewState` transitions.

```dart
class MessagesNotifier extends StreamNotifier<List<Message>> {
  MessagesNotifier(this._repository);

  final MessageRepository _repository;

  @override
  Stream<List<Message>> build() {
    return _repository.watchMessages();
  }
}
```

## Shared Async Notifier Features

Both `FutureNotifier` and `StreamNotifier` share the following features.

### Both notifiers constructor options

`initialState` (default: `LoadingState`) · `startInitialBuild` (default: `true`) · `enableEmptyState` (default: `true`) · `loadingMessage` (default: `null`) · `emptyMessage` (default: `null`).

By default, the initial state is `LoadingState`. Set `startInitialBuild` to `false` to start manually using `refresh()` or `rebuild()`. Set `enableEmptyState` to `false` to represent empty `Iterable` results as `DataState`.

### Refresh and rebuild

Use `refresh()` to rerun the current `build()` with the same inputs. Use `rebuild()` when an input that determines the result changes, such as a search query, or filter.

When the current state is `DataState`, `refresh()` keeps the existing data visible while loading. The new result replaces it when available, and if the refresh fails, the existing data is preserved.

```dart
await refresh();
await rebuild();
```

### Invalidate the current build

Use `invalidateBuild()` to invalidate the current `build()` execution without starting a replacement or changing the current state.

```dart
invalidateBuild();
```

> **Outdated builds:** ProviderKit automatically protects against outdated builds. When `refresh()` or `rebuild()` starts a new build, subsequent state updates and results from the previous build are ignored. This prevents older builds from overwriting newer state.

For asynchronous tasks outside `build()`, use `checkStaleness()` to ensure their results are still relevant before applying them to the current state.

For example, `loadNextPage()` may still be running when `rebuild()` starts a new build. If the page request completes afterward, its result is considered stale and must not be appended to the current `DataState`.

```dart
Future<void> loadNextPage() async {
  final isOperationStale = checkStaleness();

  final products = await _repository.fetchNextPage();

  if (isOperationStale()) return;

  state = DataState([...state.data, ...products]);
}
```

The captured staleness check returns `true` after a refresh, rebuild, build invalidation, or disposal. It does not cancel the underlying asynchronous task.

### State setters

Use these helpers to update the current `ViewState`:

`setInitial()` · `setLoading()` · `setData(data)` · `setEmpty()` · `setError(error, stackTrace)`

ProviderKit automatically applies configured messages, maps error information, and attaches the appropriate refresh or retry callbacks to empty and error states.

### Error handling

When an asynchronous build fails, ProviderKit creates an `ErrorState`. Besides the original error and stack trace, `ErrorState` contains an `ErrorInfo` object with user-facing error details, such as a message and error code.

This allows your UI to display a meaningful error through `errorInfo.message` without needing to understand individual exception types.
ProviderKit uses `ErrorInfoMapper` to convert the original error and stack trace into `ErrorInfo`.
Configure it once at application startup

```dart
void main() {
  ProviderKit.configure(
    errorInfoMapper: (error, stackTrace) {
      if (error is AuthException) {
        return const ErrorInfo(
          message: 'Authentication failed.',
          code: 'authentication_failed',
        );
      }

      return ErrorInfo(message: error.toString());
    },
  );

  runApp(const MyApp());
}
```

Configuring `ErrorInfoMapper` is optional. If omitted, ProviderKit uses `error.toString()` as the default error message.

## View State Widgets

View State Widgets work with `ViewState<T>` and automatically respond to changes between `InitialState`, `LoadingState`, `DataState`, `EmptyState`, and `ErrorState`.

They work with `ViewStateNotifier`, `FutureNotifier`, and `StreamNotifier`.

ProviderKit provides three widgets:

- `ViewStateBuilder` — builds the UI based on the current state.
- `ViewStateListener` — listens for state changes and performs side effects without rebuilding the UI.
- `ViewStateConsumer` — combines listening and building in one widget.

Each widget supports direct listenable access, `.of` for context-based
resolution, and `.multi` for combining multiple listenables.

### ViewStateBuilder

Use `ViewStateBuilder` to build the UI based on the current state.

```dart
ViewStateBuilder.of<ProductsNotifier, List<Product>>(
  dataBuilder: (context, products, _) => ProductsList(products: products),
);
```

You can customize the UI for individual states using `initialBuilder`,
`loadingBuilder`, `emptyBuilder`, and `errorBuilder`.

### ViewStateListener

Use `ViewStateListener` to perform side effects when a specific state is reached.

```dart
ViewStateListener.of<ProductsNotifier, List<Product>>(
  dataStateListener: (context, products) {
    showToast('${products.length} products loaded');
  },
  child: const ProductsView(),
);
```
You can listen for individual states using `initialStateListener`,
`loadingStateListener`, `emptyStateListener`, and `errorStateListener`.

### ViewStateConsumer

Use `ViewStateConsumer` when you need both state-specific side effects and UI rebuilding.

```dart
ViewStateConsumer.of<ProductsNotifier, List<Product>>(
  dataStateListener: (context, products) {
    showToast('${products.length} products loaded');
  },
  dataBuilder: (context, products, _) => ProductsList(products: products),
);
```
It also supports the optional state-specific listeners and builders available
on `ViewStateListener` and `ViewStateBuilder`.

### ViewStateWidgetsProvider

`ViewStateWidgetsProvider` lets you configure default widgets for initial, loading, empty, and error states once and reuse them throughout the widget tree.
These defaults are automatically used by View State Builders and Consumers whenever a corresponding custom builder isn't provided.

For app-wide defaults, wrap your `MaterialApp` with `ViewStateWidgetsProvider`. It must be available above the View State Widgets that rely on these defaults.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewStateWidgetsProvider(
      initialStateBuilder: (_, isSliver) =>
          MyInitialWidget(isSliver),
      loadingStateBuilder: (_, details, isSliver) =>
          MyLoadingWidget(message: details.message),
      emptyStateBuilder: (_, details, isSliver) =>
          MyEmptyWidget(message: details.message),
      errorStateBuilder: (_, details, isSliver) =>
          MyErrorWidget(message: details.message),

      // Example localization with easy_localization
      messageResolver: (context, message) => context.tr(message),

      child: const MaterialApp(),
    );
  }
}
```
The `messageResolver` localizes messages from `ErrorInfoMapper` (`ErrorInfo.message`) and messages configured through `LoadingState.message` and `EmptyState.message`. View State Widgets resolve these messages before passing them to the corresponding state builders or listeners.

#### Scoped overrides

Use `ViewStateWidgetsProvider.override` to customize specific state widgets for a subtree. Unspecified builders inherit their parent's configuration.

```dart
ViewStateWidgetsProvider.override(
  context: context,
  loadingStateBuilder: (_, details, isSliver) {
    const widget = ProfileSkeletonLoader();
    return isSliver ? SliverToBoxAdapter(child: widget) : widget;
  },
  child: const ProfileView(),
);
```


### Multi-View State Widgets

The `.multi` constructors let you combine the `ViewState` of multiple notifiers and treat them as a single `ViewState`. The combined view state is then used to determine which state-specific `builder` or `listener` is called. They are available on `ViewStateBuilder`, `ViewStateListener`, and `ViewStateConsumer`.


<p>
  <img
    src="https://github.com/user-attachments/assets/2cdc892c-190c-4c7d-b61f-2d181ee63b63"
     width="630"
     height="240"
    alt="Multi View State Widgets Demo"
  />
</p>

#### Combined state priority

When combining multiple `ViewState` values, ProviderKit uses the following priority:

**`ErrorState` → `InitialState` → `LoadingState` → `EmptyState` → `DataState`**

- **ErrorState:** Used when any notifier is in an error state. The first error provides the error details, while retry callbacks from all retryable errors are combined.
- **InitialState:** Used when no errors exist and at least one notifier is in initial state.
- **LoadingState:** Used when no errors or initial states exist and at least one notifier is in loading state. The first loading state provides the message, and available progress values are combined.
- **EmptyState:** Used when no higher-priority state exists and at least one notifier is empty. The first empty state provides its details.
- **DataState:** Used only when all listenables contain data. Their values are combined into a single typed state.

> If one listenable is in `EmptyState` while others contain data, the combined state is `EmptyState`. Set `enableEmptyState: false` on the corresponding async notifier when you want an empty collection to remain `DataState`.

#### Combining multiple view states

```dart
ViewStateBuilder.multi(
  listenables: () => (
    movie: of<MovieNotifier>().watch,
    similarMovies: of<SimilarMoviesNotifier>().watch,
    trailers: trailersNotifier.watch,
  ),
  dataBuilder: (context, state, child) {
    return MovieDetailsView(
      movie: state.movie.data,
      similarMovies: state.similarMovies.data,
      trailers: state.trailers.data,
    );
  },
);
```

For `ViewStateBuilder.multi` and `ViewStateConsumer.multi`, the default widgets configured through `ViewStateWidgetsProvider` are used for states without custom builders. You can override them using the corresponding state builders.


## Cache Mixins

ProviderKit provides two cache mixins for retaining and restoring `ViewState` data.

### ExViewStateCacheMixin

It automatically keeps track of the most recent state of each `ViewState` type as the notifier's state changes. No manual caching is required.

```dart
class ProductsNotifier extends ViewStateNotifier<List<Product>>
    with ExViewStateCacheMixin {
}
```

Access the cached states through `exInitialState`, `exLoadingState`, `exDataState`, `exEmptyState`, and `exErrorState`. Use `exDataStateObject` to access the cached `DataState` object.

Call `clearCache()` to clear all cached states.

### DataStateCacheMixin

`DataStateCacheMixin<T>` lets you cache a `DataState<T>` so you can temporarily modify the current data and restore the original data later.

This is useful for operations such as filtering, searching, or locally modifying data.

```dart
class ProductsNotifier extends FutureNotifier<List<Product>>
    with DataStateCacheMixin {
  ProductsNotifier(this._repository);

  final ProductRepository _repository;

  @override
  Future<List<Product>> build() async {
    final products = await _repository.fetchProducts();

    cacheDataState(DataState(products));
    return products;
  }

  void clearFilter() {
    final cachedState = cachedDataState;

    if (cachedState != null) {
      state = cachedState;
      clearDataStateCache();
    }
  }
}
```

Use `cacheDataState()` to save a `DataState` for later restoration. Access the cached state through `cachedDataState`, or just its data through `cachedData`. Call `clearDataStateCache()` when you no longer need the cached value.

---

## Mutation

`Mutation<T>` manages the state of asynchronous operations such as signing in, submitting forms, or updating data. It exposes idle, loading, success, and error states so the UI can react to each operation.

<p>
  <img
    src="https://github.com/user-attachments/assets/4a715400-0477-4567-988d-3e16d8e299b4"
    width="400"
    alt="Mutation demo"
  />
</p>


### Global configuration

You can optionally configure the default concurrency policy and error mapping once at application startup:

```dart
void main() {
  ProviderKit.configure(
    mutationConcurrency: MutationConcurrency.ignoreIfBusy,
    errorInfoMapper: (error, stackTrace) {
      if (error is AuthException) {
        return const ErrorInfo(
          message: 'Authentication failed.',
          code: 'authentication_failed',
        );
      }

      return ErrorInfo(message: error.toString());
    },
  );

  runApp(const MyApp());
}
```

The default concurrency policy is `parallel` when not configured. The configured `ErrorInfoMapper` is also used to create consistent error information for failed mutations.


A mutation progresses through four states:
`MutationIdle` → `MutationLoading` → `MutationSuccess` or `MutationError`.


### Basic usage

Create a mutation in the class that owns the operation and reuse the same instance:

```dart
class AuthNotifier extends ChangeNotifier {
  final signInMutation = Mutation<User>();

  Future<MutationResult<User>> signIn(
    String email,
    String password,
  ) {
    return signInMutation.run(
      () => Api.signIn(email, password),
    );
  }

  @override
  void dispose() {
    signInMutation.dispose();
    super.dispose();
  }
}
```

### Listening to mutation state

When a `Mutation` is owned by a notifier and exposed through a provider, use `StateBuilder.select` to retrieve and observe it.

The `selector` callback receives the provided notifier and returns the nested `Mutation` to observe. ProviderKit automatically subscribes to the selected mutation and reevaluates the selector when the provider notifies its dependents, allowing it to follow a replacement mutation.

```dart
StateBuilder.select<AuthNotifier, MutationState<User>>(
  selector: (auth) => auth.signInMutation,
  builder: (context, state, child) {
    return state.when(
      idle: () => const Text('Sign in'),
      loading: () => const CircularProgressIndicator(),
      success: (user) => Text('Welcome, ${user.name}'),
      error: (errorInfo, error, stackTrace) =>
          Text(errorInfo.message),
    );
  },
);
```

`selector` selects the mutation from the current provider instance. This is useful when the provider can be replaced, such as with `ProxyProvider`, because the widget can follow the newly supplied mutation instead of retaining a reference to the previous instance.

When you own a stable mutation instance, passing it directly through `listenable` is also fine.

### Handling execution results

`run()` returns a `MutationResult<T>` describing the outcome of that specific execution:

- `MutationSucceeded<T>` — contains the returned data.
- `MutationErrored<T>` — contains the error, stack trace, and mapped `ErrorInfo`.
- `MutationIgnored<T>` — indicates that the execution was ignored.

Use `result.when()` to handle each outcome:

```dart
final result = await authNotifier.signIn(email, password);

result.when(
  succeeded: (user) {
    // Continue after successful sign-in.
  },
  errored: (errorInfo, error, stackTrace) {
    showToast(errorInfo.message);
  },
  ignored: (reason) {
    // No action needed.
  },
);
```

Errors thrown by the mutation action are returned as `MutationErrored` rather than being rethrown.. You can also provide optional `onSuccess` and `onError` callbacks to `run()`.

Use `MutationState` to observe the current mutation state reactively, and `MutationResult` to handle the outcome of a particular execution.

### Execution concurrency

Mutations support four concurrency policies:

- `parallel` — allows concurrent executions.
- `latestOnly` — only the latest execution can publish its outcome.
- `ignoreIfBusy` — ignores new executions while one is running.
- `queue` — executes requests sequentially in FIFO order.

The default is `parallel`. You can override it for an individual mutation:

```dart
final signInMutation = Mutation<User>(
  concurrency: MutationConcurrency.ignoreIfBusy,
);
```

### Reset and disposal

Call `reset()` to return the mutation to `MutationIdle` and invalidate active, uncommitted and queued executions.

```dart
signInMutation.reset();
```

Resetting doesn't cancel the underlying asynchronous operations; their invalidated outcomes are ignored.
Dispose the mutation when its owning notifier is disposed. A disposed mutation cannot be used again.

```dart
signInMutation.dispose();
```
## MutationGroup

`MutationGroup<T>` manages multiple independent mutations using unique keys. It is particularly useful for lists where each item needs its own mutation state, such as deleting individual items.

<p>
  <img
    src="https://github.com/user-attachments/assets/06c6d0d3-e764-4b2c-b546-4ed0460cc8fa"
    width="213" height="261"
    alt="Mutation Demo"
  />
</p>

### Basic usage

Create a group and retrieve a mutation using an item's key:

```dart
final deleteTodo = MutationGroup<void>(
  concurrency: MutationConcurrency.ignoreIfBusy,
);

final mutation = deleteTodo(todo.id);

await mutation.run(
  () => Api.deleteTodo(todo.id),
);
```

Each key maintains its own `Mutation` instance and state. Repeated lookups for the same key return the same cached instance while it remains available.

### Automatic disposal

Keyed mutations are automatically disposed when they have no listeners and no pending executions. Loading mutations remain alive until their executions finish.

Use `keepAliveStates` to retain completed success or error states when needed.

```dart
final deleteTodo = MutationGroup<void>(
  keepAliveStates: {
    KeepAliveState.success,
    KeepAliveState.error,
  },
);
```

Dispose the group when its owning notifier is disposed:

```dart
deleteTodo.dispose();
```

---

## StateField

`StateField<T>` is a lightweight reactive field for managing supporting state independently from a notifier's main state.
It is useful for keeping values such as search queries, filters, sorting options, and UI preferences separate from the main data state.

For example, a products notifier can keep its query configuration in a
`StateField` while `FutureNotifier` manages the loaded products:

```dart
class ProductsNotifier extends FutureNotifier<List<Product>> {
  ProductsNotifier(this._repository);

  final ProductRepository _repository;

  final query = StateField(const ProductSearchQuery());

  @override
  Future<List<Product>> build() {
    return _repository.fetchItems(query.state);
  }

  Future<void> updateQuery(ProductSearchQuery value) async {
    query.state = value;
    await rebuild();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }
}
```

Each `StateField` can be observed independently using ProviderKit state widgets:

```dart
StateBuilder(
  listenable: notifier.query,
  builder: (context, query, child) {
    return SearchFilters(query: query);
  },
);
```

You can use `StateField` with ProviderKit's state widgets, including their `.select` and `.multi` variants.

Fields owned by a notifier should be disposed when their owner is disposed. Use ProviderKit's automatic resource disposal mixins to manage their lifecycle without manually disposing each field.

See [Automatic Resource Disposal](#automatic-resource-disposal) for details.

> **Tip:** Use `StateField` for supporting values that benefit from independent state and notifications, while keeping your main data state focused on the data it manages.


## Automatic Resource Disposal

ProviderKit provides resource mixins that automatically dispose resources when their owning `ChangeNotifier` or `State` is disposed.

They manage the lifecycle of `StateField`, `Mutation`, `MutationGroup`, `Debounce`, and `Throttle`, so you don't need to dispose each resource manually.

### NotifierResourcesMixin

Use `NotifierResourcesMixin` with any `ChangeNotifier`, including ProviderKit notifiers:

```dart
class SearchNotifier extends ChangeNotifier
    with NotifierResourcesMixin {
  late final searchQuery = field('');
  late final searchMutation = mutation<List<Movie>>();
  late final searchGroup = mutationGroup<void>();
  late final searchDebounce = debounce();
  late final searchThrottle = throttle();
}
```

`ResourceNotifier` is a convenience base class that combines `ChangeNotifier`
with `NotifierResourcesMixin`:

```dart
class SearchNotifier extends ResourceNotifier {
  late final searchQuery = field('');
  late final searchMutation = mutation<List<Movie>>();
}
```

### StateResourcesMixin

Use `StateResourcesMixin` with the `State` of a `StatefulWidget`:

```dart
class _SearchPageState extends State<SearchPage>
    with StateResourcesMixin<SearchPage> {
  late final searchQuery = field('');
  late final searchDebounce = debounce();
}
```

Declare resources using `late final` so they are created lazily when first accessed and disposed automatically with their owner.

### Shared debounce and throttle helpers

For simple debounced or throttled operations, use `debounceRun()` and `throttleRun()` instead of creating dedicated instances:

```dart
debounceRun(() => search(query));

throttleRun(() => submit());
```

Each mixin maintains one shared `Debounce` and `Throttle`, created lazily on first use. Calls without a key share the same operation, while different keys maintain independent operations:

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

`Debounce` and `Throttle` are provided by [`rate_kit`](https://pub.dev/packages/rate_kit), which ProviderKit uses for its rate-limiting utilities. See its documentation for the complete API.

## NestedStateListener

`NestedStateListener` lets you combine multiple state listeners under a single widget without manually nesting them.
It supports `StateListener`, `ViewStateListener`, and their `.multi` constructors.

```dart
NestedStateListener(
  listeners: [
    StateListener.of<AuthNotifier, AuthState>(
      listener: (context, state) {
        // Handle authentication state changes.
      },
    ),
    ViewStateListener.of<ProductsNotifier, List<Product>>(
      dataStateListener: (context, products) {
        // Handle product updates.
      },
    ),
    StateListener.multi(
      listenables: () => (
        cart: cartNotifier.watch,
        wishlist: wishlistNotifier.watch,
      ),
      listener: (context, state) {
        // Handle combined state changes.
      },
    ),
  ],
  child: const MyChildWidget(),
);
```
---

## NotifierObserver

`NotifierObserver` lets you monitor the lifecycle and state changes of ProviderKit notifiers. It is useful for debugging, logging, analytics, and other application-wide monitoring.

### Debugging with DebugNotifierObserver

Use `DebugNotifierObserver` to log notifier events during development.
Add it to your existing `ProviderKit.configure()` call at application startup:

```dart
void main() {
  ProviderKit.configure(
    observer: DebugNotifierObserver(),
    // Other global configuration...
  );

  runApp(const MyApp());
}
```

`DebugNotifierObserver` uses `debugPrint` to log notifier creation, state changes, errors, and disposal to the debug console.
For custom logging or analytics, extend `NotifierObserver` and override `onCreate`, `onChange`, `onError`, and `onDispose`.


## VS Code Extension

Speed up ProviderKit development with **ProviderKit Snippets**, a VS Code extension with ready-to-use Dart snippets for common ProviderKit boilerplate.

Type `pk` in a Dart file to discover the available snippets.

[Install VS Code Extension — ProviderKit Snippets](https://marketplace.visualstudio.com/items?itemName=Ram-Prasanth.providerkit-snippets)

---

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