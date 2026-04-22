# leak_sniffer

Sniff out forgotten disposals before they become memory leaks.

`leak_sniffer` is a `custom_lint` package for Dart and Flutter that detects class-owned resources that are created but never cleaned up.

## What It Catches

- `avoid_unclosed_stream_controller`
  Detects `StreamController` fields created by a class but never closed with `close()`.
- `avoid_uncancelled_stream_subscription`
  Detects `StreamSubscription` fields created by a class but never cancelled with `cancel()`.
- `avoid_undisposed_controller`
  Detects common Flutter disposable controllers and nodes that are created but never disposed with `dispose()`, including:
  `TextEditingController`, `AnimationController`, `ScrollController`, `FocusNode`, `TabController`, and `PageController`.

## Current Scope

The first version is intentionally practical:

- It focuses on class-owned fields rather than every possible local variable flow.
- It prioritizes `StatefulWidget` `State` classes and also works well for bloc-like classes that expose `dispose()` or `close()`.
- It supports direct cleanup calls and helper methods invoked from `dispose()` or `close()`.

## Installation

Add the package alongside `custom_lint`:

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  leak_sniffer: ^0.1.0
```

Then enable the rules in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - avoid_unclosed_stream_controller
    - avoid_uncancelled_stream_subscription
    - avoid_undisposed_controller
```

## Usage Examples

### StreamController

```dart
class SearchState {
  final StreamController<String> _queryController = StreamController<String>();

  void dispose() {}
}
```

The class owns `_queryController`, but it never calls `_queryController.close()`.

```dart
class SearchState {
  final StreamController<String> _queryController = StreamController<String>();

  Future<void> dispose() async {
    await _queryController.close();
  }
}
```

### StreamSubscription

```dart
class FeedCubit {
  late final StreamSubscription<int> _subscription;

  FeedCubit() {
    _subscription = stream.listen((_) {});
  }

  Future<void> close() async {}
}
```

The class owns `_subscription`, but it never calls `_subscription.cancel()`.

```dart
class FeedCubit {
  late final StreamSubscription<int> _subscription;

  FeedCubit() {
    _subscription = stream.listen((_) {});
  }

  Future<void> close() async {
    await _subscription.cancel();
  }
}
```

### Flutter Controllers And Nodes

```dart
class ExampleState extends State<ExampleWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }
}
```

The class owns `_controller`, but it never calls `_controller.dispose()`.

```dart
class ExampleState extends State<ExampleWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Example App

This repository includes a real Flutter example app at `apps/leak_sniffer_example` with:

- invalid samples that should trigger each lint
- valid samples that should pass
- `// expect_lint:` assertions for `custom_lint`

## Local Development

From the repository root:

```bash
./tool/bootstrap.sh
./tool/watch.sh
```

Or with `make`:

```bash
make setup
make watch
```

## Run And Test

Use the repository automation to analyze, test, and verify the example app:

```bash
./tool/test.sh
```

That script runs:

- `dart analyze` for the lint package
- `dart test` for rule tests
- `flutter analyze` for the example app
- `flutter test` for the example app
- `dart run custom_lint` for end-to-end lint verification

## Implementation Notes

- Built with `custom_lint`
- Uses AST analysis against resolved class declarations
- Tracks ownership through field initializers, constructor field initializers, and assignment expressions
- Searches cleanup paths rooted in `dispose()` and `close()`

## Publishing

Before publishing to pub.dev, update package metadata such as repository links and release notes, then publish from `packages/leak_sniffer`.
