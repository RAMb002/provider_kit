# ProviderKit Snippets

[![ProviderKit](https://img.shields.io/badge/ProviderKit-pub.dev-0175C2?logo=dart)](https://pub.dev/packages/provider_kit)
[![Pub Points](https://img.shields.io/pub/points/provider_kit?logo=dart)](https://pub.dev/packages/provider_kit)
[![License: BSD 2-Clause](https://img.shields.io/badge/License-BSD%202--Clause-blue.svg)](https://opensource.org/license/bsd-2-clause/)

**ProviderKit Snippets** is a lightweight Visual Studio Code extension that provides handy Dart snippets for [ProviderKit](https://pub.dev/packages/provider_kit), a Flutter toolkit built around Flutter's `ChangeNotifier` and `Listenable` APIs.

Type a `pk` prefix, choose a snippet, press `Tab`, and keep coding.

<p>
  <img
    width="100%"
    alt="Snippets demo"
    src="https://github.com/user-attachments/assets/2d463256-548f-409c-af26-117f2f7429c4"
  />
</p>

---

## Installation

Install **ProviderKit Snippets** directly from the [VS Code Marketplace](https://marketplace.visualstudio.com/).

Once installed, open any `.dart` file and start typing a `pk` prefix. IntelliSense will display the available snippets automatically.

---

## Usage

1. Type a snippet prefix (e.g., `pkStateBuilder`) in a Dart file.
2. Select the snippet from the IntelliSense dropdown.
3. Press `Tab` to insert the template.
4. Fill in the placeholder values (e.g., notifier classes, state types).

### Quick Preview

Type `pkStateBuilder` + `Tab` to generate:

```dart
StateBuilder(
  listenable: myNotifier,
  builder: (context, state, child) {
    return widget;
  },
)
```

*For a complete list of all available snippets, see the table below.*
---

## Available Snippets

### Notifiers

| Prefix | Notifier |
|--------|----------|
| pkStateNotifier | `StateNotifier` |
| pkViewStateNotifier | `ViewStateNotifier` |
| pkFutureNotifier | `FutureNotifier` |
| pkStreamNotifier | `StreamNotifier` |

### State Widgets

| Prefix | Widget |
|--------|--------|
| pkStateBuilder | `StateBuilder` |
| pkStateBuilderOf | `StateBuilder.of` |
| pkStateBuilderSelect | `StateBuilder.select` |
| pkStateBuilderMulti | `StateBuilder.multi` |
| pkStateListener | `StateListener` |
| pkStateListenerOf | `StateListener.of` |
| pkStateListenerSelect | `StateListener.select` |
| pkStateListenerMulti | `StateListener.multi` |
| pkStateConsumer | `StateConsumer` |
| pkStateConsumerOf | `StateConsumer.of` |
| pkStateConsumerSelect | `StateConsumer.select` |
| pkStateConsumerMulti | `StateConsumer.multi` |
| pkWatchBuilder | `WatchBuilder` |

### ViewState Widgets

| Prefix | Widget |
|--------|--------|
| pkViewStateBuilder | `ViewStateBuilder` |
| pkViewStateBuilderOf | `ViewStateBuilder.of` |
| pkViewStateBuilderMulti | `ViewStateBuilder.multi` |
| pkViewStateListener | `ViewStateListener` |
| pkViewStateListenerOf | `ViewStateListener.of` |
| pkViewStateListenerMulti | `ViewStateListener.multi` |
| pkViewStateConsumer | `ViewStateConsumer` |
| pkViewStateConsumerOf | `ViewStateConsumer.of` |
| pkViewStateConsumerMulti | `ViewStateConsumer.multi` |

### ViewState Configuration

| Prefix | Widget |
|--------|--------|
| pkViewStateWidgetsProvider | `ViewStateWidgetsProvider` |


---

## Design

ProviderKit Snippets follows a **minimalist, developer-first** approach:

- **Simple** — install the extension and start using snippets immediately.
- **Consistent naming** — every snippet starts with `pk`, making ProviderKit snippets easy to find.
- **Clean snippets** — only commonly used parameters are included, keeping generated code concise.
- **Useful tab stops** — move quickly between placeholders with `Tab`.

---

## Related Links

- **ProviderKit on pub.dev**: [provider_kit](https://pub.dev/packages/provider_kit)
- **ProviderKit GitHub**: [github.com/RAMb002/provider_kit](https://github.com/RAMb002/provider_kit)
- **Report an issue**: [GitHub Issues](https://github.com/RAMb002/provider_kit/issues)

---

##  Contributing

Found a bug or have a suggestion for a new snippet? We welcome contributions!

Please open an issue or submit a pull request on the [ProviderKit GitHub repository](https://github.com/RAMb002/provider_kit). When reporting snippet issues, include the exact prefix and the generated code.

---

## 📄 License

Distributed under the **BSD 2-Clause License**. See the [LICENSE](LICENSE) file for more details.