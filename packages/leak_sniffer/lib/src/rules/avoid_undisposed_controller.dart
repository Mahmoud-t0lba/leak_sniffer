// ignore_for_file: deprecated_member_use

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/resource_spec.dart';

class AvoidUndisposedControllerRule extends DartLintRule {
  const AvoidUndisposedControllerRule() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_undisposed_controller',
    problemMessage: 'Flutter controller and node fields created by a class should be disposed in dispose() or close().',
    correctionMessage:
        'Call dispose() on the controller or node from a lifecycle method before the class is discarded.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _resourceAnalyzer = ClassResourceAnalyzer(
    specs: [
      ResourceSpec(
        debugName: 'TextEditingController',
        typeChecker: TypeChecker.fromName('TextEditingController', packageName: 'flutter'),
        cleanupAction: CleanupAction.dispose,
      ),
      ResourceSpec(
        debugName: 'AnimationController',
        typeChecker: TypeChecker.fromName('AnimationController', packageName: 'flutter'),
        cleanupAction: CleanupAction.dispose,
      ),
      ResourceSpec(
        debugName: 'ScrollController',
        typeChecker: TypeChecker.fromName('ScrollController', packageName: 'flutter'),
        cleanupAction: CleanupAction.dispose,
      ),
      ResourceSpec(
        debugName: 'FocusNode',
        typeChecker: TypeChecker.fromName('FocusNode', packageName: 'flutter'),
        cleanupAction: CleanupAction.dispose,
      ),
      ResourceSpec(
        debugName: 'TabController',
        typeChecker: TypeChecker.fromName('TabController', packageName: 'flutter'),
        cleanupAction: CleanupAction.dispose,
      ),
      ResourceSpec(
        debugName: 'PageController',
        typeChecker: TypeChecker.fromName('PageController', packageName: 'flutter'),
        cleanupAction: CleanupAction.dispose,
      ),
    ],
  );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      for (final field in _resourceAnalyzer.findLeakingFields(node)) {
        reporter.atNode(field.variable, code);
      }
    });
  }
}
