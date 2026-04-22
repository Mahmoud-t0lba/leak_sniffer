import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:collection/collection.dart';

import '../analysis/class_resource_analyzer.dart';

class LifecycleCleanupEdit {
  const LifecycleCleanupEdit({
    required this.message,
    required this.offset,
    required this.text,
  });

  final String message;
  final int offset;
  final String text;
}

TrackedField? findTrackedFieldForDiagnostic({
  required ClassDeclaration owner,
  required ClassResourceAnalyzer resourceAnalyzer,
  required int diagnosticOffset,
}) {
  return resourceAnalyzer
      .findLeakingFields(owner)
      .firstWhereOrNull(
        (field) => containsOffset(field.reportNode, diagnosticOffset),
      );
}

TrackedField? findTrackedFieldForTarget(
  List<TrackedField> leakingFields,
  SourceRange target, {
  required ClassDeclaration owner,
}) {
  final directMatch = leakingFields.firstWhereOrNull(
    (field) => intersectsTarget(field.reportNode, target),
  );
  if (directMatch != null) {
    return directMatch;
  }

  final targetIsInsideOwner = intersectsTarget(owner, target);
  if (targetIsInsideOwner && leakingFields.length == 1) {
    return leakingFields.single;
  }

  return null;
}

List<TrackedField> uniqueTrackedFields(Iterable<TrackedField> trackedFields) {
  final fieldsByName = <String, TrackedField>{};
  for (final trackedField in trackedFields) {
    fieldsByName.putIfAbsent(trackedField.name, () => trackedField);
  }

  final uniqueFields = fieldsByName.values.toList()
    ..sort((a, b) => a.variable.offset.compareTo(b.variable.offset));
  return uniqueFields;
}

LifecycleCleanupEdit? buildLifecycleCleanupEdit({
  required ClassDeclaration node,
  required List<TrackedField> trackedFields,
  required String source,
  required LineInfo lineInfo,
  String? messageOverride,
}) {
  if (trackedFields.isEmpty) {
    return null;
  }

  final lifecycleTemplate = _inferLifecycleTemplate(node);
  final targetMethod = _pickTargetMethod(node, lifecycleTemplate.methodName);

  return targetMethod == null
      ? _buildCreateLifecycleMethodEdit(
          node: node,
          trackedFields: trackedFields,
          lifecycleTemplate: lifecycleTemplate,
          source: source,
          lineInfo: lineInfo,
          messageOverride: messageOverride,
        )
      : _buildInsertCleanupCallEdit(
          method: targetMethod,
          trackedFields: trackedFields,
          source: source,
          lineInfo: lineInfo,
          messageOverride: messageOverride,
        );
}

bool containsOffset(AstNode node, int offset) {
  return node.offset <= offset && offset <= node.end;
}

bool intersectsTarget(AstNode node, SourceRange target) {
  final targetStart = target.offset;
  final targetEnd = target.offset + target.length;
  final nodeStart = node.offset;
  final nodeEnd = node.end;

  if (target.length == 0) {
    return nodeStart <= targetStart && targetStart <= nodeEnd;
  }

  return targetStart <= nodeEnd && targetEnd >= nodeStart;
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

LifecycleCleanupEdit? _buildInsertCleanupCallEdit({
  required MethodDeclaration method,
  required List<TrackedField> trackedFields,
  required String source,
  required LineInfo lineInfo,
  String? messageOverride,
}) {
  final body = method.body;
  if (body is! BlockFunctionBody) {
    return null;
  }

  final methodIndent = _indentOfOffset(source, lineInfo, method.offset);
  final statementIndent = _statementIndent(
    body,
    source,
    lineInfo,
    methodIndent,
  );
  final cleanupLines = _cleanupLines(trackedFields);
  final cleanupBlock = cleanupLines.join('\n$statementIndent');
  final insertionPoint = _statementInsertionOffset(
    body: body,
    source: source,
    lineInfo: lineInfo,
    lifecycleMethodName: method.name.lexeme,
  );

  final text = insertionPoint.beforeExistingStatement
      ? '$statementIndent$cleanupBlock\n'
      : insertionPoint.isSingleLineBody
      ? '\n$statementIndent$cleanupBlock\n$methodIndent'
      : '$statementIndent$cleanupBlock\n';

  return LifecycleCleanupEdit(
    message:
        messageOverride ??
        (trackedFields.length == 1
            ? 'Add ${cleanupLines.single.trim()} to ${method.name.lexeme}()'
            : 'Add cleanup calls to ${method.name.lexeme}()'),
    offset: insertionPoint.offset,
    text: text,
  );
}

LifecycleCleanupEdit _buildCreateLifecycleMethodEdit({
  required ClassDeclaration node,
  required List<TrackedField> trackedFields,
  required _LifecycleTemplate lifecycleTemplate,
  required String source,
  required LineInfo lineInfo,
  String? messageOverride,
}) {
  final classIndent = _indentOfOffset(source, lineInfo, node.offset);
  final memberIndent = _memberIndent(node, source, lineInfo, classIndent);
  final statementIndent = '$memberIndent  ';
  final cleanupLines = _cleanupLines(trackedFields);
  final cleanupBlock = cleanupLines.join('\n$statementIndent');
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
      '$statementIndent$cleanupBlock'
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

  return LifecycleCleanupEdit(
    message:
        messageOverride ??
        (trackedFields.length == 1
            ? 'Create ${lifecycleTemplate.methodName}() and call ${cleanupLines.single.trim()}'
            : 'Create ${lifecycleTemplate.methodName}() and cleanup resources'),
    offset: insertionOffset,
    text: text,
  );
}

List<String> _cleanupLines(List<TrackedField> trackedFields) {
  return trackedFields
      .map(
        (trackedField) =>
            '${trackedField.name}.${trackedField.spec.cleanupMethodName}();',
      )
      .toList(growable: false);
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
