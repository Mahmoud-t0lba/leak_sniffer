import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'rules/avoid_unclosed_stream_controller.dart';
import 'rules/avoid_uncancelled_stream_subscription.dart';
import 'rules/avoid_undisposed_controller.dart';

class LeakSnifferPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    AvoidUnclosedStreamControllerRule(),
    AvoidUncancelledStreamSubscriptionRule(),
    AvoidUndisposedControllerRule(),
  ];
}
