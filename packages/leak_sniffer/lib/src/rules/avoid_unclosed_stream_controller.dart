// ignore_for_file: deprecated_member_use

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/leak_resource_analyzers.dart';
import '../fixes/add_lifecycle_cleanup_fix.dart';

class AvoidUnclosedStreamControllerRule extends DartLintRule {
  const AvoidUnclosedStreamControllerRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_unclosed_stream_controller',
    problemMessage:
        'Stream controller-like fields created by a class should be closed from a lifecycle cleanup method.',
    correctionMessage:
        'Call close() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _resourceAnalyzer = streamControllerResourceAnalyzer;

  static final _fix = AddLifecycleCleanupFix(
    resourceAnalyzer: _resourceAnalyzer,
    classResourceAnalyzer: allLeakSnifferResourceAnalyzer,
  );

  static ClassResourceAnalyzer get resourceAnalyzer => _resourceAnalyzer;

  @override
  List<Fix> getFixes() => [_fix];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      for (final field in _resourceAnalyzer.findLeakingFields(node)) {
        reporter.atNode(field.reportNode, code);
      }
    });
  }
}
