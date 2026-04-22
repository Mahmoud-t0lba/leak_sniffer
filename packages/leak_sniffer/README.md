# leak_sniffer

Sniff out forgotten disposals before they become memory leaks.

`leak_sniffer` is a plug-and-play lint package for Dart and Flutter that detects class-owned resources that are created but never cleaned up.

## What It Catches

- `avoid_unclosed_bloc_or_cubit`
  Detects `Bloc`, `Cubit`, and `BlocBase`-style fields created by a class but never closed with `close()`.
- `avoid_unclosed_stream_controller`
  Detects `StreamController` and subject-like fields created by a class but never closed with `close()`.
- `avoid_uncancelled_timer`
  Detects `Timer` fields created by a class but never cancelled with `cancel()`.
- `avoid_uncancelled_stream_subscription`
  Detects `StreamSubscription` fields created by a class but never cancelled with `cancel()`.
- `avoid_undisposed_controller`
  Detects common Flutter disposable resources that are created but never disposed with `dispose()`, including
  controllers, nodes, `ChangeNotifier`, `ValueNotifier`, and other types with common disposable suffixes.

## Current Scope

The first version is intentionally practical:

- It focuses on class-owned fields rather than every possible local variable flow.
- It works across common lifecycle owners such as `StatefulWidget` `State`, `Cubit`/`Bloc`, `ChangeNotifier`,
  Provider-like classes, GetX-style `onClose()`, and custom classes that expose `dispose()`, `close()`, `cancel()`,
  or `onClose()`.
- It supports direct cleanup calls and helper methods invoked from those lifecycle methods.

## Quick Start

Install only `leak_sniffer`:

```yaml
dev_dependencies:
  leak_sniffer: ^0.1.0
```

Then run:

```bash
dart run leak_sniffer
```

That command configures `analysis_options.yaml` for you automatically.

If you want to configure the project and run the lints immediately:

```bash
dart run leak_sniffer --check
```

If you want watch mode while coding:

```bash
dart run leak_sniffer --watch
```

Manual setup still works too if you want it:

```yaml
include: package:leak_sniffer/analysis_options.yaml
```

`leak_sniffer` bundles `custom_lint` internally, activates the plugin automatically, and enables all bundled rules by default. The consumer does not need to install `custom_lint`, add `analyzer.plugins`, or list rules manually.

For CLI and CI runs, use:

```bash
dart run leak_sniffer --check
```

Under the hood, this runs `custom_lint`, but the consumer does not need to depend on it directly.

If the project already has an `analysis_options.yaml`, `dart run leak_sniffer` keeps your existing include/config where possible and layers `custom_lint` into it automatically.

## IDE Quick Fixes

When `leak_sniffer` reports a resource leak, the editor `Quick Fix` and `Show Context Actions` menus can suggest a matching cleanup fix automatically.

- `Timer` -> add `cancel()`
- `StreamSubscription` -> add `cancel()`
- `StreamController`, bloc/cubit-like resources -> add `close()`
- controllers, notifiers, and other disposable resources -> add `dispose()`

The fix will try to reuse an existing lifecycle method such as `dispose()`, `close()`, or `onClose()`. If no suitable lifecycle method exists, it can create one for common owners such as `State`, `Cubit`/`Bloc`, `ChangeNotifier`, and GetX-style controllers.

When multiple resources in the same class are leaking, `Show Context Actions` can also offer a class-level cleanup action to fix all missing cleanups in that class at once.

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

### Timer

```dart
class PollingCubit {
  late final Timer _timer;

  PollingCubit() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  Future<void> close() async {}
}
```

The class owns `_timer`, but it never calls `_timer.cancel()`.

```dart
class PollingCubit {
  late final Timer _timer;

  PollingCubit() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {});
  }

  Future<void> close() async {
    _timer.cancel();
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

## Developing leak_sniffer

These commands are for working on the `leak_sniffer` package itself, not for applications that consume it.

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
- a consumer smoke test that installs only `leak_sniffer` and runs `dart run leak_sniffer --check`

## Implementation Notes

- Built with `custom_lint`
- Ships a ready-to-include `package:leak_sniffer/analysis_options.yaml`
- Uses AST analysis against resolved class declarations
- Tracks ownership through field initializers, constructor field initializers, and assignment expressions
- Searches cleanup paths rooted in `dispose()`, `close()`, `cancel()`, and `onClose()`

## Publishing

Before publishing to pub.dev, update package metadata such as repository links and release notes, then publish from `packages/leak_sniffer`.
