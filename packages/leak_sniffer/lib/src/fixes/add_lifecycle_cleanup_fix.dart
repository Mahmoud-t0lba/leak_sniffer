// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart'
    hide
        // ignore: undefined_hidden_name, Needed to support lower analyzer versions
        LintCode;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../analysis/class_resource_analyzer.dart';

class AddLifecycleCleanupFix extends DartFix {
  AddLifecycleCleanupFix({required this.resourceAnalyzer});

  final ClassResourceAnalyzer resourceAnalyzer;

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!_containsOffset(node, analysisError.offset)) {
        return;
      }

      final trackedField = resourceAnalyzer
          .findLeakingFields(node)
          .firstWhereOrNull(
            (field) => _containsOffset(field.reportNode, analysisError.offset),
          );
      if (trackedField == null) {
        return;
      }

      final source = resolver.source.contents.data;
      final edit = _buildCleanupEdit(
        node: node,
        trackedField: trackedField,
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

      final trackedField = _fieldForTarget(leakingFields, target, owner: node);
      if (trackedField == null) {
        return;
      }

      final source = resolver.source.contents.data;
      final edit = _buildCleanupEdit(
        node: node,
        trackedField: trackedField,
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

class _CleanupEdit {
  const _CleanupEdit({
    required this.message,
    required this.offset,
    required this.text,
  });

  final String message;
  final int offset;
  final String text;
}

class _LifecycleTemplate {
  const _LifecycleTemplate({
    required this.methodName,
    required this.signature,
    this.superStatement,
    this.addOverride = false,
  });

  final String methodName;
  final String signature;
  final String? superStatement;
  final bool addOverride;
}

TrackedField? _fieldForTarget(
  List<TrackedField> leakingFields,
  SourceRange target, {
  required ClassDeclaration owner,
}) {
  final directMatch = leakingFields.firstWhereOrNull(
    (field) => _intersectsTarget(field.reportNode, target),
  );
  if (directMatch != null) {
    return directMatch;
  }

  final targetIsInsideOwner = _intersectsTarget(owner, target);
  if (targetIsInsideOwner && leakingFields.length == 1) {
    return leakingFields.single;
  }

  return null;
}

_CleanupEdit? _buildCleanupEdit({
  required ClassDeclaration node,
  required TrackedField trackedField,
  required String source,
  required LineInfo lineInfo,
}) {
  final lifecycleTemplate = _inferLifecycleTemplate(node);
  final targetMethod = _pickTargetMethod(node, lifecycleTemplate.methodName);

  return targetMethod == null
      ? _buildCreateLifecycleMethodEdit(
          node: node,
          trackedField: trackedField,
          lifecycleTemplate: lifecycleTemplate,
          source: source,
          lineInfo: lineInfo,
        )
      : _buildInsertCleanupCallEdit(
          method: targetMethod,
          trackedField: trackedField,
          source: source,
          lineInfo: lineInfo,
        );
}

_CleanupEdit? _buildInsertCleanupCallEdit({
  required MethodDeclaration method,
  required TrackedField trackedField,
  required String source,
  required LineInfo lineInfo,
}) {
  final body = method.body;
  if (body is! BlockFunctionBody) {
    return null;
  }

  final cleanupCall =
      '${trackedField.name}.${trackedField.spec.cleanupMethodName}();';
  final methodIndent = _indentOfOffset(source, lineInfo, method.offset);
  final statementIndent = _statementIndent(
    body,
    source,
    lineInfo,
    methodIndent,
  );
  final insertionPoint = _statementInsertionOffset(
    body: body,
    source: source,
    lineInfo: lineInfo,
    lifecycleMethodName: method.name.lexeme,
  );

  final text = insertionPoint.beforeExistingStatement
      ? '$statementIndent$cleanupCall\n'
      : insertionPoint.isSingleLineBody
      ? '\n$statementIndent$cleanupCall\n$methodIndent'
      : '$statementIndent$cleanupCall\n';

  return _CleanupEdit(
    message: 'Add $cleanupCall to ${method.name.lexeme}()',
    offset: insertionPoint.offset,
    text: text,
  );
}

_CleanupEdit _buildCreateLifecycleMethodEdit({
  required ClassDeclaration node,
  required TrackedField trackedField,
  required _LifecycleTemplate lifecycleTemplate,
  required String source,
  required LineInfo lineInfo,
}) {
  final cleanupCall =
      '${trackedField.name}.${trackedField.spec.cleanupMethodName}();';
  final classIndent = _indentOfOffset(source, lineInfo, node.offset);
  final memberIndent = _memberIndent(node, source, lineInfo, classIndent);
  final statementIndent = '$memberIndent  ';
  final openingLine = node.members.isEmpty ? '' : '\n';
  final overrideAnnotation = lifecycleTemplate.addOverride
      ? '$memberIndent@override\n'
      : '';
  final superLine = lifecycleTemplate.superStatement == null
      ? ''
      : '\n$statementIndent${lifecycleTemplate.superStatement}';

  final methodText =
      '$overrideAnnotation'
      '$memberIndent${lifecycleTemplate.signature} {\n'
      '$statementIndent$cleanupCall'
      '$superLine\n'
      '$memberIndent}\n';

  final leftBracketLine = lineInfo
      .getLocation(node.leftBracket.offset)
      .lineNumber;
  final rightBracketLine = lineInfo
      .getLocation(node.rightBracket.offset)
      .lineNumber;
  final isSingleLineClass = leftBracketLine == rightBracketLine;
  final insertionOffset = isSingleLineClass
      ? node.rightBracket.offset
      : lineInfo.getOffsetOfLine(rightBracketLine - 1);
  final text = isSingleLineClass
      ? '\n$methodText$classIndent'
      : '$openingLine$methodText';

  return _CleanupEdit(
    message: 'Create ${lifecycleTemplate.methodName}() and call $cleanupCall',
    offset: insertionOffset,
    text: text,
  );
}

MethodDeclaration? _pickTargetMethod(
  ClassDeclaration node,
  String preferredMethodName,
) {
  final methodsByName = {
    for (final member in node.members)
      if (member is MethodDeclaration &&
          !member.isStatic &&
          !member.isGetter &&
          !member.isSetter)
        member.name.lexeme: member,
  };

  final orderedNames = <String>[
    preferredMethodName,
    'dispose',
    'close',
    'onClose',
    'cancel',
  ];

  for (final methodName in orderedNames) {
    final method = methodsByName[methodName];
    if (method != null) {
      return method;
    }
  }

  return null;
}

_LifecycleTemplate _inferLifecycleTemplate(ClassDeclaration node) {
  final ownerTypes = _ownerTypeNames(node);

  if (ownerTypes.any(
    (type) => type.endsWith('Cubit') || type.endsWith('Bloc'),
  )) {
    return const _LifecycleTemplate(
      methodName: 'close',
      signature: 'Future<void> close()',
      superStatement: 'return super.close();',
      addOverride: true,
    );
  }

  if (ownerTypes.any(_isGetxLikeType)) {
    return const _LifecycleTemplate(
      methodName: 'onClose',
      signature: 'void onClose()',
      superStatement: 'super.onClose();',
      addOverride: true,
    );
  }

  if (ownerTypes.any(_isDisposeSuperType)) {
    return const _LifecycleTemplate(
      methodName: 'dispose',
      signature: 'void dispose()',
      superStatement: 'super.dispose();',
      addOverride: true,
    );
  }

  return const _LifecycleTemplate(
    methodName: 'dispose',
    signature: 'void dispose()',
  );
}

Iterable<String> _ownerTypeNames(ClassDeclaration node) sync* {
  final extendsClause = node.extendsClause;
  if (extendsClause != null) {
    yield _simpleTypeName(extendsClause.superclass);
  }

  final withClause = node.withClause;
  if (withClause != null) {
    for (final mixin in withClause.mixinTypes) {
      yield _simpleTypeName(mixin);
    }
  }

  final implementsClause = node.implementsClause;
  if (implementsClause != null) {
    for (final interface in implementsClause.interfaces) {
      yield _simpleTypeName(interface);
    }
  }
}

String _simpleTypeName(NamedType type) {
  final source = type.toSource();
  return source.split('<').first.split('.').last;
}

bool _isGetxLikeType(String typeName) {
  return const {
    'GetxController',
    'GetxService',
    'FullLifeCycleController',
    'SuperController',
  }.contains(typeName);
}

bool _isDisposeSuperType(String typeName) {
  return const {'State', 'ChangeNotifier', 'ValueNotifier'}.contains(typeName);
}

String _memberIndent(
  ClassDeclaration node,
  String source,
  LineInfo lineInfo,
  String classIndent,
) {
  final firstMember = node.members.firstWhereOrNull(
    (member) => member is! Comment,
  );
  if (firstMember == null) {
    return '$classIndent  ';
  }

  return _indentOfOffset(source, lineInfo, firstMember.offset);
}

String _statementIndent(
  BlockFunctionBody body,
  String source,
  LineInfo lineInfo,
  String methodIndent,
) {
  final firstStatement = body.block.statements.firstOrNull;
  if (firstStatement != null) {
    return _indentOfOffset(source, lineInfo, firstStatement.offset);
  }

  return '$methodIndent  ';
}

_InsertionPoint _statementInsertionOffset({
  required BlockFunctionBody body,
  required String source,
  required LineInfo lineInfo,
  required String lifecycleMethodName,
}) {
  for (final statement in body.block.statements) {
    if (statement is ReturnStatement ||
        _referencesSuperLifecycle(statement, lifecycleMethodName)) {
      final statementLine =
          lineInfo.getLocation(statement.offset).lineNumber - 1;
      return _InsertionPoint(
        offset: lineInfo.getOffsetOfLine(statementLine),
        beforeExistingStatement: true,
        isSingleLineBody: false,
      );
    }
  }

  final leftBracketLine = lineInfo
      .getLocation(body.block.leftBracket.offset)
      .lineNumber;
  final rightBracketLine = lineInfo
      .getLocation(body.block.rightBracket.offset)
      .lineNumber;
  final isSingleLineBody = leftBracketLine == rightBracketLine;

  return _InsertionPoint(
    offset: isSingleLineBody
        ? body.block.rightBracket.offset
        : lineInfo.getOffsetOfLine(rightBracketLine - 1),
    beforeExistingStatement: false,
    isSingleLineBody: isSingleLineBody,
  );
}

bool _referencesSuperLifecycle(
  Statement statement,
  String lifecycleMethodName,
) {
  final source = statement.toSource();
  return source.contains('super.$lifecycleMethodName(');
}

String _indentOfOffset(String source, LineInfo lineInfo, int offset) {
  final lineNumber = lineInfo.getLocation(offset).lineNumber - 1;
  final lineStart = lineInfo.getOffsetOfLine(lineNumber);
  final segment = source.substring(lineStart, offset);
  final trimmedLength = segment.trimLeft().length;
  return segment.substring(0, segment.length - trimmedLength);
}

bool _containsOffset(AstNode node, int offset) {
  return node.offset <= offset && offset <= node.end;
}

bool _intersectsTarget(AstNode node, SourceRange target) {
  final targetStart = target.offset;
  final targetEnd = target.offset + target.length;
  final nodeStart = node.offset;
  final nodeEnd = node.end;

  if (target.length == 0) {
    return nodeStart <= targetStart && targetStart <= nodeEnd;
  }

  return targetStart <= nodeEnd && targetEnd >= nodeStart;
}

class _InsertionPoint {
  const _InsertionPoint({
    required this.offset,
    required this.beforeExistingStatement,
    required this.isSingleLineBody,
  });

  final int offset;
  final bool beforeExistingStatement;
  final bool isSingleLineBody;
}
