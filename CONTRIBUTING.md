# Contributing to HoldIt

Thank you for your interest in contributing! Please read through this guide before submitting a pull request.

By participating in this project, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Started

1. Fork and clone the repository:
   ```bash
   git clone git@github.com:YOUR_USERNAME/hold-it.git
   cd hold-it
   ```
2. Open `ShelfKit.xcodeproj` in Xcode 15+
3. Select the **ShelfKit** scheme and build (Cmd+B)

> The app is an `LSUIElement` (menu bar only) — it will not show a dock icon when running.

## Running Tests

- In Xcode: **Cmd+U**
- From the command line:
  ```bash
  xcodebuild test -project ShelfKit.xcodeproj -scheme ShelfKit
  ```

Tests are in the `ShelfKitTests` target. All tests run on `@MainActor`.

## Code Style

- Standard Swift conventions
- `@MainActor` isolation for all UI-bound types
- Prefer `guard ... else { return }` for early exits
- Use `isEmpty == false` rather than `!isEmpty` (established project convention)
- No force unwraps in production code (test code is fine)
- Structs for value types (`Shelf`, `ShelfItem`, `DragPreviewDescriptor`), classes for controllers and coordinators

## Submitting Changes

1. Create a feature branch from `main`
2. Write tests for new functionality
3. Make sure all existing tests pass
4. Open a pull request with a clear description
5. Reference any related issues (e.g., "Fixes #12")

## Reporting Bugs and Requesting Features

Please use the [issue templates](https://github.com/Anmolnoor/hold-it/issues/new/choose) to file structured bug reports or feature requests.

## License

By contributing to HoldIt, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).
