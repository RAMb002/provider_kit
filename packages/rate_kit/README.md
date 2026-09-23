
# rate_kit

Lightweight, pure-Dart utilities for controlling the timing and frequency of operations.

- [Debounce](#debounce)
- [Throttle](#throttle)

## Debounce

`Debounce` delays an operation until calls have stopped for the configured duration.

Each new call replaces the previous pending operation and restarts the timer. Once no new call occurs within the duration, the latest operation is executed.

This is useful for operations such as search, input validation, filtering, autosave, and API requests.

### Basic usage

```dart
final debounce = Debounce();

debounce.run(() {
  searchUsers(query);
});
```

The default duration is **300 milliseconds**.

For example:

```text
User types:  f → fl → flu → flut → flutt → flutte → flutter
                                                            ↓
                                                     search("flutter")
                                                       after 300ms
```

Because no new call occurs for 300 milliseconds after the last call, only `search("flutter")` is executed.

### Custom duration

Set a default duration when creating the `Debounce`:

```dart
final debounce = Debounce(
  duration: const Duration(milliseconds: 500),
);
```

You can also override the duration for an individual call:

```dart
debounce.run(
  () => searchUsers(query),
  duration: const Duration(milliseconds: 500),
);
```

### Trailing

By default, `Debounce` uses trailing execution. These are equivalent:

```dart
final debounce = Debounce();
```

```dart
final debounce = Debounce(
  trailing: true,
);
```

**Trailing** waits until calls have stopped, then executes the latest operation:

```text
Typing:    f → fl → flu → flutter
                                      ↓
                                runs "flutter"
```

### Leading

When `leading` is `true` and `trailing` is not configured, trailing execution defaults to `false`.

```dart
final debounce = Debounce(
  leading: true,
);
```
**Leading** executes the first operation immediately:

```text
Typing:    f → fl → flu → flutter
           ↓
        runs "f"
```

### Leading and Trailing

It executes the first operation immediately and the latest operation after calls have stopped:

```dart
final debounce = Debounce(
  leading: true,
  trailing: true,
);
```

```text
Typing:    f → fl → flu → flutter
           ↓                         ↓
        runs "f"               runs "flutter"
```

### Maximum wait

Use `maxWait` when you want to prevent a debounce from waiting indefinitely while new calls keep arriving.

```dart
final debounce = Debounce(
  duration: const Duration(milliseconds: 300),
  maxWait: const Duration(seconds: 2),
);
```

For example, if the user keeps typing, the 300ms timer keeps restarting:

```text
Typing:        f → fl → flu → flut → flutt → flutte → flutter → ...

300ms timer:   ↻   ↻    ↻     ↻      ↻       ↻        ↻
                    keeps resetting with every new call

maxWait:                       2 seconds
                                  ↓
                           latest operation runs
```

Without `maxWait`, the debounce can keep waiting as long as new calls continue to arrive. With `maxWait`, the cycle ends after 2 seconds even if new calls continue to arrive.

### Pending

Check whether a debounce cycle is currently active:

```dart
if (debounce.isPending()) {
  // A debounce cycle is active.
}
```

`isPending()` returns `true` while the debounce cycle is active, including the waiting period of a leading-only debounce.

### Cancel

Cancel the current cycle without executing its pending operation:

```dart
debounce.cancel();
```

Cancellation clears the current cycle, and the same `Debounce` can be reused.

### Flush

Flush the current cycle and execute its pending trailing operation immediately:

```dart
debounce.flush();
```

When no cycle is active, `flush()` does nothing.

### Dispose

Dispose the `Debounce` when it is no longer needed:

```dart
debounce.dispose();
```

### Debounce with keys

A `Debounce` can manage multiple independent debounces using keys. Each key
has its own debounce, so calls made with one key do not affect debounces using
other keys. The same `Debounce` instance can manage as many keys as needed.

```dart
final debounce = Debounce();

debounce.run(
  () => searchUsers(query),
  key: 'users',
);

debounce.run(
  () => searchMovies(query),
  key: 'movies',
);
```

Each key has its own independent debounce cycle.
Calling `run()` again with the same key replaces that key's pending operation
and restarts its debounce timer.

You can also check, cancel, or flush a specific key:

```dart
debounce.isPending(key: 'users');

debounce.cancel(key: 'users');

debounce.flush(key: 'users');
```

Dispose only a specific keyed debounce:

```dart
debounce.dispose(key: 'users');
```

The `Debounce` instance remains usable.

Calling `dispose()` without a key disposes the entire instance, including all keyed debounces it manages.

---

## Throttle

`Throttle` limits how often an operation can execute.

Unlike `Debounce`, which waits for calls to stop, `Throttle` uses a fixed time period. New calls during the period do not restart the timer.

This is useful for operations such as button actions, scroll events, drag events, analytics, and API requests.

### Basic usage

```dart
final throttle = Throttle();

throttle.run(() {
  sendAnalytics();
});
```

The default duration is **300 milliseconds**.

By default, the first call executes immediately, and calls during the throttle period are ignored.

For example:

```text
Calls:    ●         ●         ●         ●         ●
          ↓         ×         ×         ↓         ×
         RUN     ignored   ignored     RUN      ignored

          │─────────────────────────────│
                        300ms
```

Once the throttle period ends, the next call can execute.

### Custom duration

Set a default duration when creating the `Throttle`:

```dart
final throttle = Throttle(
  duration: const Duration(milliseconds: 500),
);
```

The duration is fixed for each throttle period. Calls made while the period
is active cannot change it.

### Leading

By default, `Throttle` uses leading execution. These are equivalent:

```dart
final throttle = Throttle();
```

```dart
final throttle = Throttle(
  leading: true,
);
```
**Leading** executes the first operation immediately. Calls made during the throttle period are ignored:

```text
Time →    0ms       100ms      200ms      300ms      400ms
           │          │          │          │          │
Calls →    ●          ●          ●          ●          ●
           ↓          ×          ×          ↓          ×
         runs      ignored    ignored     runs      ignored

           │────────────────────────────────│
                         300ms
```

### Trailing

When `trailing` is `true` and `leading` is not configured, leading execution defaults to `false`.

```dart
final throttle = Throttle(
  trailing: true,
);
```

**Trailing** waits until the end of the throttle period, then executes the latest operation:


```text
Time →    0ms       100ms      200ms      300ms
           │          │          │          │
Calls →    ●          ●          ●          │
           │          │          │          │
        pending    replace    replace   runs latest

           │────────────────────────────────│
                         300ms
```

Each new call during the period replaces the previous pending operation.

### Leading and Trailing

It executes the first operation immediately and the latest operation at the end of the throttle period:

```dart
final throttle = Throttle(
  leading: true,
  trailing: true,
);
```

```text
Time →    0ms       100ms      200ms      300ms
           │          │          │          │
Calls →    ●          ●          ●          │
           ↓          │          │          ↓
         runs      replace    replace    runs latest

           │────────────────────────────────│
                         300ms
```

With both enabled, a single call executes only once. The trailing operation runs only when another call occurs during the throttle period.

### Fixed throttle period

A throttle period is fixed. New calls do not extend or restart it.

After a trailing operation executes, a new throttle period starts immediately. This ensures consecutive executions are always separated by at least the configured duration.

### Status

Check whether a throttle period is currently active:

```dart
throttle.isThrottled();
```

Check whether a trailing operation is waiting to execute:

```dart
throttle.isTrailingPending();
```

`isThrottled()` returns `true` while the throttle period is active.

`isTrailingPending()` returns `true` only when a trailing operation is waiting to execute.

### Cancel

Cancel the current throttle period:

```dart
throttle.cancel();
```

Cancellation also discards any pending trailing operation, and the same `Throttle` can be reused.

### Flush

Flush the current throttle and execute its pending trailing operation immediately:

```dart
throttle.flush();
```

Flushing starts a new throttle period from the time `flush()` is called.

When no trailing operation is pending, `flush()` does nothing.

### Dispose

Dispose the `Throttle` when it is no longer needed:

```dart
throttle.dispose();
```

### Throttle with keys

A `Throttle` can manage multiple independent throttles using keys. Each key has its own throttle period, so calls made with one key do not affect throttles using other keys.

```dart
final throttle = Throttle();

throttle.run(
  () => updateUsers(),
  key: 'users',
);

throttle.run(
  () => updateMovies(),
  key: 'movies',
);
```

Each key has its own independent throttle.

Calling `run()` again with the same key is handled by that key's throttle. With trailing execution, it replaces that key's pending operation.

You can also check, cancel, or flush a specific key:

```dart
throttle.isThrottled(key: 'users');
throttle.isTrailingPending(key: 'users');

throttle.cancel(key: 'users');
throttle.flush(key: 'users');
```

Dispose only a specific keyed throttle:

```dart
throttle.dispose(key: 'users');
```

The `Throttle` instance remains usable.

Calling `dispose()` without a key disposes the entire instance, including all keyed throttles it manages.