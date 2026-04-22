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
