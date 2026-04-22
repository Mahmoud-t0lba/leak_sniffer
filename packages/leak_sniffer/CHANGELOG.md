## 0.1.3

- Restored `dart analyze` and `flutter analyze` diagnostics by shipping `leak_sniffer` as a modern analyzer plugin, not only as a `custom_lint` package.
- Restored `Show Context Actions` and quick-fix cleanup suggestions for leak diagnostics reported through the analyzer plugin.
- Updated the setup CLI to wire both the analyzer plugin and `custom_lint` automatically in consumer projects.
- Pinned analyzer plugin dependencies to compatible versions so consumer projects do not crash during analysis or `custom_lint` startup.

## 0.1.2

- Added package screenshots metadata so the banner appears on `pub.dev`.
- Updated the package `README` to display the published banner image.

## 0.1.1

- Renamed the packaged analysis include to `package:leak_sniffer/leak_sniffer.yaml` to avoid `pub.dev`/`pana` analyzer failures caused by nested `analysis_options.yaml` files in `custom_lint` packages.
- Updated the setup CLI to migrate legacy `package:leak_sniffer/analysis_options.yaml` includes automatically.
- Moved `analyzer_plugin` to `dev_dependencies` because it is only used by tests.

## 0.1.0

- Initial production-style starter release.
- Bundled `custom_lint` and a packaged `analysis_options.yaml` for one-install setup.
- Added `dart run leak_sniffer` automatic project setup and run/watch commands.
- Added `avoid_unclosed_bloc_or_cubit`.
- Added `avoid_unclosed_stream_controller`.
- Added `avoid_uncancelled_timer`.
- Added `avoid_uncancelled_stream_subscription`.
- Added `avoid_undisposed_controller`.
