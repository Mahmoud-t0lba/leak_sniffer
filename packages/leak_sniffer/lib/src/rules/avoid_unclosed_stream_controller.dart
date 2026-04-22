// ignore_for_file: deprecated_member_use

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/resource_spec.dart';

class AvoidUnclosedStreamControllerRule extends DartLintRule {
  const AvoidUnclosedStreamControllerRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_unclosed_stream_controller',
    problemMessage: 'StreamController fields created by a class should be closed in dispose() or close().',
    correctionMessage: 'Call close() on the controller from a lifecycle method before the class is discarded.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _resourceSpec = ResourceSpec(
    debugName: 'StreamController',
    typeChecker: TypeChecker.fromUrl('dart:async#StreamController'),
    cleanupAction: CleanupAction.close,
  );

  static const _resourceAnalyzer = ClassResourceAnalyzer(specs: [_resourceSpec]);

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      for (final field in _resourceAnalyzer.findLeakingFields(node)) {
        reporter.atNode(field.variable, code);
      }
    });
  }
}
