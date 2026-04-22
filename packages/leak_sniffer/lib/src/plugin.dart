import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'analysis/leak_resource_analyzers.dart';
import 'fixes/add_lifecycle_cleanup_fix.dart';
import 'rules/avoid_unclosed_bloc_or_cubit.dart';
import 'rules/avoid_unclosed_stream_controller.dart';
import 'rules/avoid_uncancelled_timer.dart';
import 'rules/avoid_uncancelled_stream_subscription.dart';
import 'rules/avoid_undisposed_controller.dart';

class LeakSnifferPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    AvoidUnclosedBlocOrCubitRule(),
    AvoidUnclosedStreamControllerRule(),
    AvoidUncancelledTimerRule(),
    AvoidUncancelledStreamSubscriptionRule(),
    AvoidUndisposedControllerRule(),
  ];

  @override
  List<Assist> getAssists() => [
    AddLifecycleCleanupAssist(resourceAnalyzer: allLeakSnifferResourceAnalyzer),
    AddAllLifecycleCleanupAssist(
      resourceAnalyzer: allLeakSnifferResourceAnalyzer,
    ),
  ];
}
