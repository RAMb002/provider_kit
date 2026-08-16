# ProviderKit Snippets

[![VS Code Version](https://img.shields.io/badge/VS%20Code-1.74.0+-blue.svg)](https://code.visualstudio.com/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10.0+-blue.svg)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p>
  <img
    width="720"
    height="440"
    alt="Snippets demo"
    src="https://github.com/user-attachments/assets/ce6d937b-7322-485f-845b-aaecaf00f78a"
  />
</p>

**ProviderKit Snippets** is a lightweight Visual Studio Code extension that provides useful Dart snippets for the [provider_kit](https://pub.dev/packages/provider_kit) state management library.

Type a `pk` prefix, choose a snippet, press `Tab`, and keep coding.



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
StateBuilder<MyState>(
  provider: provider,
  builder: (context, state, child) {
    return widget;
  },
)
```

*For a complete list of all available snippets, see the table below.*
---

## Available Snippets

All snippets are prefixed with `pk` for fast discovery and to avoid collisions with other snippet libraries.

### Providers

| Prefix | Provider |
|--------|-----------|
| `pkStateNotifier` |  `StateNotifier` class |
| `pkViewStateNotifier` |  `ViewStateNotifier` class |
| `pkAsyncViewStateNotifier` |  `AsyncViewStateNotifier` class |

### State Widgets

| Prefix | Widget |
|--------|-----------|
| `pkStateBuilder` | `StateBuilder` |
| `pkStateBuilderOf` | `StateBuilder.of` |
| `pkStateListener` | `StateListener` |
| `pkStateListenerOf` | `StateListener.of` |
| `pkStateConsumer` | `StateConsumer` |
| `pkStateConsumerOf` | `StateConsumer.of` |

### Multi-State Widgets

| Prefix | Widget |
|--------|-----------|
| `pkMultiStateBuilder` | `MultiStateBuilder` |
| `pkMultiStateListener` | `MultiStateListener` |
| `pkMultiStateConsumer` | `MultiStateConsumer` |

### ViewState Widgets

| Prefix | Widget |
|--------|-----------|
| `pkViewStateBuilder` | `ViewStateBuilder` |
| `pkViewStateBuilderOf` | `ViewStateBuilder.of` |
| `pkViewStateListener` | `ViewStateListener` |
| `pkViewStateListenerOf` | `ViewStateListener.of` |
| `pkViewStateConsumer` | `ViewStateConsumer` |
| `pkViewStateConsumerOf` | `ViewStateConsumer.of` |

### Multi-ViewState Widgets

| Prefix | Widget |
|--------|-----------|
| `pkMultiViewStateBuilder` | `MultiViewStateBuilder` |
| `pkMultiViewStateListener` | `MultiViewStateListener` |
| `pkMultiViewStateConsumer` | `MultiViewStateConsumer` |

### ViewState Providers

| Prefix | Widget |
|--------|-----------|
| `pkViewStateWidgetsProvider` | `ViewStateWidgetsProvider` |


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

Distributed under the MIT License. See the [LICENSE](https://github.com/RAMb002/provider_kit/blob/main/LICENSE) file for more details.