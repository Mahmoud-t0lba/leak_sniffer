library;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/plugin.dart';

export 'src/rules/avoid_unclosed_stream_controller.dart';
export 'src/rules/avoid_uncancelled_stream_subscription.dart';
export 'src/rules/avoid_undisposed_controller.dart';

PluginBase createPlugin() => LeakSnifferPlugin();
