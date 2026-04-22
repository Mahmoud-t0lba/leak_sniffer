// ignore_for_file: deprecated_member_use

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/leak_resource_analyzers.dart';
import '../fixes/add_lifecycle_cleanup_fix.dart';

class AvoidUndisposedControllerRule extends DartLintRule {
  const AvoidUndisposedControllerRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_undisposed_controller',
    problemMessage:
        'Disposable Flutter resource fields created by a class should be disposed from a lifecycle cleanup method.',
    correctionMessage:
        'Call dispose() from a lifecycle method such as dispose(), close(), cancel(), or onClose().',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _resourceAnalyzer = disposableControllerResourceAnalyzer;

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
