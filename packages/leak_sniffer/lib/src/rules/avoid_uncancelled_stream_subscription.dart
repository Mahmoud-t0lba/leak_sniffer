// ignore_for_file: deprecated_member_use

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/resource_spec.dart';

class AvoidUncancelledStreamSubscriptionRule extends DartLintRule {
  const AvoidUncancelledStreamSubscriptionRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_uncancelled_stream_subscription',
    problemMessage: 'StreamSubscription fields created by a class should be cancelled in dispose() or close().',
    correctionMessage: 'Call cancel() on the subscription from a lifecycle method before the class is discarded.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _resourceSpec = ResourceSpec(
    debugName: 'StreamSubscription',
    typeChecker: TypeChecker.fromUrl('dart:async#StreamSubscription'),
    cleanupAction: CleanupAction.cancel,
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
