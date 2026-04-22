// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart'
    hide
        // ignore: undefined_hidden_name, Needed to support lower analyzer versions
        LintCode;
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';
import 'lifecycle_cleanup_edits.dart';

class AddLifecycleCleanupFix extends DartFix {
  AddLifecycleCleanupFix({
    required this.resourceAnalyzer,
    this.classResourceAnalyzer,
  });

  final ClassResourceAnalyzer resourceAnalyzer;
  final ClassResourceAnalyzer? classResourceAnalyzer;

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!containsOffset(node, analysisError.offset)) {
        return;
      }

      final trackedField = findTrackedFieldForDiagnostic(
        owner: node,
        resourceAnalyzer: resourceAnalyzer,
        diagnosticOffset: analysisError.offset,
      );
      if (trackedField == null) {
        return;
      }

      final source = resolver.source.contents.data;
      final edit = buildLifecycleCleanupEdit(
        node: node,
        trackedFields: [trackedField],
        source: source,
        lineInfo: resolver.lineInfo,
      );
      if (edit == null) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: edit.message,
        priority: 90,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(edit.offset, edit.text);
      });

      final fixAllAnalyzer = classResourceAnalyzer;
      if (fixAllAnalyzer == null) {
        return;
      }

      final classFields = uniqueTrackedFields(
        fixAllAnalyzer.findLeakingFields(node),
      );
      if (classFields.length < 2) {
        return;
      }

      final fixAllEdit = buildLifecycleCleanupEdit(
        node: node,
        trackedFields: classFields,
        source: source,
        lineInfo: resolver.lineInfo,
        messageOverride: 'Fix all missing cleanups in this class',
      );
      if (fixAllEdit == null) {
        return;
      }

      final fixAllBuilder = reporter.createChangeBuilder(
        message: fixAllEdit.message,
        priority: 80,
      );
      fixAllBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(fixAllEdit.offset, fixAllEdit.text);
      });
    });
  }
}

class AddLifecycleCleanupAssist extends DartAssist {
  AddLifecycleCleanupAssist({required this.resourceAnalyzer});

  final ClassResourceAnalyzer resourceAnalyzer;

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!_intersectsTarget(node, target)) {
        return;
      }

      final leakingFields = resourceAnalyzer.findLeakingFields(node);
      if (leakingFields.isEmpty) {
        return;
      }

      final trackedField = findTrackedFieldForTarget(
        leakingFields,
        target,
        owner: node,
      );
      if (trackedField == null) {
        return;
      }

      final source = resolver.source.contents.data;
      final edit = buildLifecycleCleanupEdit(
        node: node,
        trackedFields: [trackedField],
        source: source,
        lineInfo: resolver.lineInfo,
      );
      if (edit == null) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: edit.message,
        priority: 70,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(edit.offset, edit.text);
      });
    });
  }
}

class AddAllLifecycleCleanupAssist extends DartAssist {
  AddAllLifecycleCleanupAssist({required this.resourceAnalyzer});

  final ClassResourceAnalyzer resourceAnalyzer;

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!_intersectsTarget(node, target)) {
        return;
      }

      final trackedFields = uniqueTrackedFields(
        resourceAnalyzer.findLeakingFields(node),
      );
      if (trackedFields.length < 2) {
        return;
      }

      final source = resolver.source.contents.data;
      final edit = buildLifecycleCleanupEdit(
        node: node,
        trackedFields: trackedFields,
        source: source,
        lineInfo: resolver.lineInfo,
        messageOverride: 'Fix all missing cleanups in this class',
      );
      if (edit == null) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: edit.message,
        priority: 60,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(edit.offset, edit.text);
      });
    });
  }
}

bool _intersectsTarget(AstNode node, SourceRange target) {
  return intersectsTarget(node, target);
}
