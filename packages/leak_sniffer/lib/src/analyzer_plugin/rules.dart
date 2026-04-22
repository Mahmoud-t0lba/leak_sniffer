import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/leak_resource_analyzers.dart';

abstract class _LeakAnalysisRule extends AnalysisRule {
  _LeakAnalysisRule({
    required this.resourceAnalyzer,
    required this.code,
    required super.name,
    required super.description,
  });

  final DiagnosticCode code;
  final ClassResourceAnalyzer resourceAnalyzer;

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      _LeakClassVisitor(this, resourceAnalyzer),
    );
  }
}

class _LeakClassVisitor extends SimpleAstVisitor<void> {
  _LeakClassVisitor(this.rule, this.resourceAnalyzer);

  final AnalysisRule rule;
  final ClassResourceAnalyzer resourceAnalyzer;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final field in resourceAnalyzer.findLeakingFields(node)) {
      rule.reportAtNode(field.reportNode);
    }
  }
}

class AvoidUnclosedStreamControllerAnalysisRule extends _LeakAnalysisRule {
  static const diagnosticLintCode = LintCode(
    'avoid_unclosed_stream_controller',
    'Stream controller-like fields created by a class should be closed from a lifecycle cleanup method.',
    correctionMessage:
        'Call close() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUnclosedStreamControllerAnalysisRule()
    : super(
        name: diagnosticLintCode.name,
        description: diagnosticLintCode.problemMessage,
        code: diagnosticLintCode,
        resourceAnalyzer: streamControllerResourceAnalyzer,
      );
}

class AvoidUncancelledStreamSubscriptionAnalysisRule extends _LeakAnalysisRule {
  static const diagnosticLintCode = LintCode(
    'avoid_uncancelled_stream_subscription',
    'Stream subscriptions created by a class should be cancelled from a lifecycle cleanup method.',
    correctionMessage:
        'Call cancel() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUncancelledStreamSubscriptionAnalysisRule()
    : super(
        name: diagnosticLintCode.name,
        description: diagnosticLintCode.problemMessage,
        code: diagnosticLintCode,
        resourceAnalyzer: streamSubscriptionResourceAnalyzer,
      );
}

class AvoidUncancelledTimerAnalysisRule extends _LeakAnalysisRule {
  static const diagnosticLintCode = LintCode(
    'avoid_uncancelled_timer',
    'Timer fields created by a class should be cancelled from a lifecycle cleanup method.',
    correctionMessage:
        'Call cancel() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUncancelledTimerAnalysisRule()
    : super(
        name: diagnosticLintCode.name,
        description: diagnosticLintCode.problemMessage,
        code: diagnosticLintCode,
        resourceAnalyzer: timerResourceAnalyzer,
      );
}

class AvoidUnclosedBlocOrCubitAnalysisRule extends _LeakAnalysisRule {
  static const diagnosticLintCode = LintCode(
    'avoid_unclosed_bloc_or_cubit',
    'Bloc/Cubit-like fields created by a class should be closed from a lifecycle cleanup method.',
    correctionMessage:
        'Call close() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUnclosedBlocOrCubitAnalysisRule()
    : super(
        name: diagnosticLintCode.name,
        description: diagnosticLintCode.problemMessage,
        code: diagnosticLintCode,
        resourceAnalyzer: blocOrCubitResourceAnalyzer,
      );
}

class AvoidUndisposedControllerAnalysisRule extends _LeakAnalysisRule {
  static const diagnosticLintCode = LintCode(
    'avoid_undisposed_controller',
    'Disposable Flutter resource fields created by a class should be disposed from a lifecycle cleanup method.',
    correctionMessage:
        'Call dispose() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidUndisposedControllerAnalysisRule()
    : super(
        name: diagnosticLintCode.name,
        description: diagnosticLintCode.problemMessage,
        code: diagnosticLintCode,
        resourceAnalyzer: disposableControllerResourceAnalyzer,
      );
}
