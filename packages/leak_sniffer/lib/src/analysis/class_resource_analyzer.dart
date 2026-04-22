import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';

import 'resource_spec.dart';

@immutable
class TrackedField {
  const TrackedField({
    required this.name,
    required this.reportNode,
    required this.variable,
    required this.spec,
  });

  final String name;
  final AstNode reportNode;
  final VariableDeclaration variable;
  final ResourceSpec spec;
}

class ClassResourceAnalyzer {
  const ClassResourceAnalyzer({
    required List<ResourceSpec> specs,
    Set<String> lifecycleMethodNames = const {
      'dispose',
      'close',
      'cancel',
      'onClose',
    },
  }) : _specs = specs,
       _lifecycleMethodNames = lifecycleMethodNames;

  final List<ResourceSpec> _specs;
  final Set<String> _lifecycleMethodNames;

  List<TrackedField> findLeakingFields(ClassDeclaration node) {
    final fieldRecords = _collectFieldRecords(node);
    if (fieldRecords.isEmpty) {
      return const [];
    }

    _markOwnedFields(node, fieldRecords);

    final ownedFields = fieldRecords.values.where(
      (record) => record.isOwned && record.spec != null,
    );
    if (ownedFields.isEmpty) {
      return const [];
    }

    final methodBodies = _collectMethodBodies(node);
    final lifecycleRoots = methodBodies.keys.where(
      _lifecycleMethodNames.contains,
    );
    if (lifecycleRoots.isEmpty) {
      return ownedFields
          .map(
            (record) => TrackedField(
              name: record.name,
              reportNode: record.reportNode,
              variable: record.variable,
              spec: record.spec!,
            ),
          )
          .toList(growable: false);
    }

    final cleanedFieldNames = _collectCleanedFields(
      fieldRecords: fieldRecords,
      methodBodies: methodBodies,
      lifecycleRoots: lifecycleRoots,
    );

    return ownedFields
        .where((record) => !cleanedFieldNames.contains(record.name))
        .map(
          (record) => TrackedField(
            name: record.name,
            reportNode: record.reportNode,
            variable: record.variable,
            spec: record.spec!,
          ),
        )
        .toList(growable: false);
  }

  Map<String, _FieldRecord> _collectFieldRecords(ClassDeclaration node) {
    final fieldRecords = <String, _FieldRecord>{};

    for (final member in node.members) {
      if (member is! FieldDeclaration || member.isStatic) {
        continue;
      }

      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        final record = _FieldRecord(
          name: name,
          reportNode: member,
          variable: variable,
        );

        record.spec =
            _matchSpec(variable.declaredFragment?.element.type) ??
            _matchSpec(variable.initializer?.staticType);

        final initializer = variable.initializer;
        if (initializer != null && _looksLikeOwnedCreation(initializer)) {
          final initializerSpec = _matchSpec(initializer.staticType);
          if (initializerSpec != null) {
            record
              ..spec = initializerSpec
              ..isOwned = true;
          }
        }

        fieldRecords[name] = record;
      }
    }

    return fieldRecords;
  }

  void _markOwnedFields(
    ClassDeclaration node,
    Map<String, _FieldRecord> fieldRecords,
  ) {
    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        for (final initializer in member.initializers) {
          if (initializer is! ConstructorFieldInitializer) {
            continue;
          }

          _markOwnedField(
            fieldRecords: fieldRecords,
            fieldName: initializer.fieldName.name,
            expression: initializer.expression,
          );
        }

        member.body.accept(
          _OwnedFieldAssignmentVisitor(
            onAssignment: (fieldName, expression) {
              _markOwnedField(
                fieldRecords: fieldRecords,
                fieldName: fieldName,
                expression: expression,
              );
            },
          ),
        );
      }

      if (member is MethodDeclaration &&
          !member.isStatic &&
          !member.isGetter &&
          !member.isSetter) {
        member.body.accept(
          _OwnedFieldAssignmentVisitor(
            onAssignment: (fieldName, expression) {
              _markOwnedField(
                fieldRecords: fieldRecords,
                fieldName: fieldName,
                expression: expression,
              );
            },
          ),
        );
      }
    }
  }

  void _markOwnedField({
    required Map<String, _FieldRecord> fieldRecords,
    required String fieldName,
    required Expression expression,
  }) {
    final record = fieldRecords[fieldName];
    if (record == null || !_looksLikeOwnedCreation(expression)) {
      return;
    }

    final expressionSpec = _matchSpec(expression.staticType);
    if (expressionSpec == null) {
      return;
    }

    record
      ..spec ??= expressionSpec
      ..isOwned = true;
  }

  Map<String, FunctionBody> _collectMethodBodies(ClassDeclaration node) {
    final methodBodies = <String, FunctionBody>{};

    for (final member in node.members) {
      if (member is! MethodDeclaration ||
          member.isStatic ||
          member.isGetter ||
          member.isSetter) {
        continue;
      }

      methodBodies[member.name.lexeme] = member.body;
    }

    return methodBodies;
  }

  Set<String> _collectCleanedFields({
    required Map<String, _FieldRecord> fieldRecords,
    required Map<String, FunctionBody> methodBodies,
    required Iterable<String> lifecycleRoots,
  }) {
    final trackedFields = <String, ResourceSpec>{
      for (final record in fieldRecords.values)
        if (record.isOwned && record.spec != null) record.name: record.spec!,
    };
    final cleanedFields = <String>{};
    final visitedMethods = <String>{};
    final helperMethodNames = methodBodies.keys.toSet();

    void visitMethod(String methodName) {
      if (!visitedMethods.add(methodName)) {
        return;
      }

      final body = methodBodies[methodName];
      if (body == null) {
        return;
      }

      body.accept(
        _LifecycleCleanupVisitor(
          trackedFields: trackedFields,
          helperMethodNames: helperMethodNames,
          onCleanup: cleanedFields.add,
          onHelperInvocation: visitMethod,
        ),
      );
    }

    for (final methodName in lifecycleRoots) {
      visitMethod(methodName);
    }

    return cleanedFields;
  }

  ResourceSpec? _matchSpec(DartType? candidateType) {
    for (final spec in _specs) {
      if (spec.matchesType(candidateType)) {
        return spec;
      }
    }

    return null;
  }

  static bool _looksLikeOwnedCreation(Expression expression) {
    final unwrapped = _unwrapExpression(expression);
    if (unwrapped is CascadeExpression) {
      return _looksLikeOwnedCreation(unwrapped.target);
    }

    return unwrapped is FunctionExpressionInvocation ||
        unwrapped is InstanceCreationExpression ||
        unwrapped is MethodInvocation;
  }

  static Expression _unwrapExpression(Expression expression) {
    if (expression is AsExpression) {
      return _unwrapExpression(expression.expression);
    }
    if (expression is AwaitExpression) {
      return _unwrapExpression(expression.expression);
    }
    if (expression is ParenthesizedExpression) {
      return _unwrapExpression(expression.expression);
    }
    if (expression is PostfixExpression && expression.operator.lexeme == '!') {
      return _unwrapExpression(expression.operand);
    }

    return expression;
  }
}

class _FieldRecord {
  _FieldRecord({
    required this.name,
    required this.reportNode,
    required this.variable,
  });

  final String name;
  final AstNode reportNode;
  final VariableDeclaration variable;
  ResourceSpec? spec;
  bool isOwned = false;
}

class _OwnedFieldAssignmentVisitor extends RecursiveAstVisitor<void> {
  _OwnedFieldAssignmentVisitor({required this.onAssignment});

  final void Function(String fieldName, Expression expression) onAssignment;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final fieldName = _extractFieldName(node.leftHandSide);
    if (fieldName != null) {
      onAssignment(fieldName, node.rightHandSide);
    }

    super.visitAssignmentExpression(node);
  }
}

class _LifecycleCleanupVisitor extends RecursiveAstVisitor<void> {
  _LifecycleCleanupVisitor({
    required this.trackedFields,
    required this.helperMethodNames,
    required this.onCleanup,
    required this.onHelperInvocation,
  });

  final Set<String> helperMethodNames;
  final void Function(String fieldName) onCleanup;
  final void Function(String methodName) onHelperInvocation;
  final Map<String, ResourceSpec> trackedFields;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    final targetFieldName = _extractFieldName(node.target);

    if (targetFieldName != null) {
      final fieldSpec = trackedFields[targetFieldName];
      if (fieldSpec != null && fieldSpec.cleanupMethodName == methodName) {
        onCleanup(targetFieldName);
      }
    } else if (_isLocalHelperInvocation(node) &&
        helperMethodNames.contains(methodName)) {
      onHelperInvocation(methodName);
    }

    super.visitMethodInvocation(node);
  }

  bool _isLocalHelperInvocation(MethodInvocation node) {
    final target = node.target;
    return target == null || target is ThisExpression;
  }
}

String? _extractFieldName(Expression? expression) {
  if (expression == null) {
    return null;
  }

  final unwrapped = ClassResourceAnalyzer._unwrapExpression(expression);
  if (unwrapped is SimpleIdentifier) {
    return unwrapped.name;
  }
  if (unwrapped is PropertyAccess && unwrapped.target is ThisExpression) {
    return unwrapped.propertyName.name;
  }

  return null;
}
