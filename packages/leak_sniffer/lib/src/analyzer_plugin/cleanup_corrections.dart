import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import '../analysis/class_resource_analyzer.dart';
import '../analysis/leak_resource_analyzers.dart';
import '../fixes/lifecycle_cleanup_edits.dart';

abstract class _LifecycleCleanupProducer extends ResolvedCorrectionProducer {
  _LifecycleCleanupProducer({required super.context});

  ClassDeclaration? get enclosingClass =>
      node.thisOrAncestorOfType<ClassDeclaration>();

  Future<void> addCleanupEdit(
    ChangeBuilder builder, {
    required LifecycleCleanupEdit edit,
  }) {
    return builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(edit.offset, edit.text);
    });
  }
}

class AddLifecycleCleanupAnalyzerFix extends _LifecycleCleanupProducer {
  AddLifecycleCleanupAnalyzerFix({
    required super.context,
    required this.resourceAnalyzer,
  });

  static const _fixKind = FixKind(
    'leak_sniffer.fix.addLifecycleCleanup',
    DartFixKindPriority.standard,
    '{0}',
  );

  final ClassResourceAnalyzer resourceAnalyzer;
  String? _message;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String>? get fixArguments => _message == null ? null : [_message!];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classNode = enclosingClass;
    final diagnosticOffset = this.diagnosticOffset;
    if (classNode == null || diagnosticOffset == null) {
      return;
    }

    final trackedField = findTrackedFieldForDiagnostic(
      owner: classNode,
      resourceAnalyzer: resourceAnalyzer,
      diagnosticOffset: diagnosticOffset,
    );
    if (trackedField == null) {
      return;
    }

    final edit = buildLifecycleCleanupEdit(
      node: classNode,
      trackedFields: [trackedField],
      source: unitResult.content,
      lineInfo: unitResult.lineInfo,
    );
    if (edit == null) {
      return;
    }

    _message = edit.message;
    await addCleanupEdit(builder, edit: edit);
  }
}

class AddLifecycleCleanupAnalyzerAssist extends _LifecycleCleanupProducer {
  AddLifecycleCleanupAnalyzerAssist({
    required super.context,
    required this.resourceAnalyzer,
  });

  static const _assistKind = AssistKind(
    'leak_sniffer.assist.addLifecycleCleanup',
    50,
    '{0}',
  );

  final ClassResourceAnalyzer resourceAnalyzer;
  String? _message;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String>? get assistArguments => _message == null ? null : [_message!];

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classNode = enclosingClass;
    if (classNode == null) {
      return;
    }

    final leakingFields = resourceAnalyzer.findLeakingFields(classNode);
    if (leakingFields.isEmpty) {
      return;
    }

    final trackedField = findTrackedFieldForTarget(
      leakingFields,
      SourceRange(selectionOffset, selectionLength),
      owner: classNode,
    );
    if (trackedField == null) {
      return;
    }

    final edit = buildLifecycleCleanupEdit(
      node: classNode,
      trackedFields: [trackedField],
      source: unitResult.content,
      lineInfo: unitResult.lineInfo,
    );
    if (edit == null) {
      return;
    }

    _message = edit.message;
    await addCleanupEdit(builder, edit: edit);
  }
}

class AddAllLifecycleCleanupAnalyzerAssist extends _LifecycleCleanupProducer {
  AddAllLifecycleCleanupAnalyzerAssist({required super.context});

  static const _assistKind = AssistKind(
    'leak_sniffer.assist.addAllLifecycleCleanup',
    40,
    'Fix all missing cleanups in this class',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _assistKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classNode = enclosingClass;
    if (classNode == null) {
      return;
    }

    final trackedFields = uniqueTrackedFields(
      allLeakSnifferResourceAnalyzer.findLeakingFields(classNode),
    );
    if (trackedFields.length < 2) {
      return;
    }

    final edit = buildLifecycleCleanupEdit(
      node: classNode,
      trackedFields: trackedFields,
      source: unitResult.content,
      lineInfo: unitResult.lineInfo,
      messageOverride: 'Fix all missing cleanups in this class',
    );
    if (edit == null) {
      return;
    }

    await addCleanupEdit(builder, edit: edit);
  }
}
