import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/analyzer_plugin/cleanup_corrections.dart';
import 'src/analyzer_plugin/rules.dart';
import 'src/analysis/leak_resource_analyzers.dart';

final plugin = LeakSnifferAnalyzerPlugin();

class LeakSnifferAnalyzerPlugin extends Plugin {
  @override
  String get name => 'leak_sniffer';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(AvoidUnclosedBlocOrCubitAnalysisRule());
    registry.registerWarningRule(AvoidUnclosedStreamControllerAnalysisRule());
    registry.registerWarningRule(AvoidUncancelledTimerAnalysisRule());
    registry.registerWarningRule(
      AvoidUncancelledStreamSubscriptionAnalysisRule(),
    );
    registry.registerWarningRule(AvoidUndisposedControllerAnalysisRule());

    registry.registerFixForRule(
      AvoidUnclosedBlocOrCubitAnalysisRule.diagnosticLintCode,
      ({required context}) => AddLifecycleCleanupAnalyzerFix(
        context: context,
        resourceAnalyzer: blocOrCubitResourceAnalyzer,
      ),
    );
    registry.registerFixForRule(
      AvoidUnclosedStreamControllerAnalysisRule.diagnosticLintCode,
      ({required context}) => AddLifecycleCleanupAnalyzerFix(
        context: context,
        resourceAnalyzer: streamControllerResourceAnalyzer,
      ),
    );
    registry.registerFixForRule(
      AvoidUncancelledTimerAnalysisRule.diagnosticLintCode,
      ({required context}) => AddLifecycleCleanupAnalyzerFix(
        context: context,
        resourceAnalyzer: timerResourceAnalyzer,
      ),
    );
    registry.registerFixForRule(
      AvoidUncancelledStreamSubscriptionAnalysisRule.diagnosticLintCode,
      ({required context}) => AddLifecycleCleanupAnalyzerFix(
        context: context,
        resourceAnalyzer: streamSubscriptionResourceAnalyzer,
      ),
    );
    registry.registerFixForRule(
      AvoidUndisposedControllerAnalysisRule.diagnosticLintCode,
      ({required context}) => AddLifecycleCleanupAnalyzerFix(
        context: context,
        resourceAnalyzer: disposableControllerResourceAnalyzer,
      ),
    );

    registry.registerAssist(
      ({required context}) => AddLifecycleCleanupAnalyzerAssist(
        context: context,
        resourceAnalyzer: allLeakSnifferResourceAnalyzer,
      ),
    );
    registry.registerAssist(
      ({required context}) =>
          AddAllLifecycleCleanupAnalyzerAssist(context: context),
    );
  }
}
