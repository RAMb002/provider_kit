# Contributing to ProviderKit

Thank you for taking the time to contribute to ProviderKit! Contributions, bug fixes, documentation improvements, and new ideas are always welcome.

## Proposing a Change

Before starting work on a new feature, significant change, or non-trivial improvement, please **open an issue first** to discuss the proposal.

This helps ensure that the proposed change aligns with ProviderKit's goals before significant development work begins.

For bug fixes and smaller changes, you may submit a pull request directly, although opening an issue first is still recommended.

## Creating a Pull Request

Before creating a pull request, please ensure you have completed the following steps:

1. Fork the repository and create a dedicated branch from `dev`.
2. Keep your changes focused on the proposed issue or feature.
3. Discuss significant changes in the related issue before starting implementation.

### Before Submitting

1. Install all dependencies with `flutter pub get`.
2. If you've fixed a bug or added code that should be tested, add appropriate tests.
3. Pull requests without **100% test coverage** will not be approved.
4. Ensure the complete test suite passes.
5. If you've changed the public API, make sure to update or add the relevant documentation and examples.
6. Update the README or changelog when your changes affect user-facing functionality.
7. Format your code with `dart format .`.
8. Analyze your code with `dart analyze --fatal-infos --fatal-warnings .`.
9. Ensure your commits are atomic and have clear, meaningful messages. The maintainers may squash commits upon merge.
10. Create the pull request with a clear description of the changes.
11. Verify that all CI and status checks are passing.

Please make sure all of the above requirements are satisfied before requesting a review. Reviewers may request additional tests, documentation, or changes before a pull request can be approved.

## Documentation

Documentation improvements are welcome.

When changing or adding public APIs, please update the relevant documentation and examples to reflect the changes.

Documentation and examples should remain consistent with the current API.

## Tests

ProviderKit aims to maintain **100% test coverage**.

When adding or changing functionality:

- Add tests for new behavior.
- Update existing tests when behavior changes.
- Include relevant edge cases.
- Ensure the complete test suite passes before submitting a pull request.

## Code Style

Please follow the existing Dart and Flutter conventions used throughout the project.

Run `dart format` and `dart analyze` before submitting your pull request.

## License

By contributing to ProviderKit, you agree that your contributions will be licensed under the project's [BSD 2-Clause License](LICENSE).