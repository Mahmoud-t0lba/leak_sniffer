import 'package:analyzer/dart/element/type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';

enum CleanupAction { close, cancel, dispose }

extension CleanupActionX on CleanupAction {
  String get methodName {
    switch (this) {
      case CleanupAction.close:
        return 'close';
      case CleanupAction.cancel:
        return 'cancel';
      case CleanupAction.dispose:
        return 'dispose';
    }
  }
}

@immutable
class ResourceSpec {
  const ResourceSpec({
    required this.debugName,
    required this.cleanupAction,
    this.typeChecker,
    this.typeNames = const [],
    this.typeNameSuffixes = const [],
  });

  final String debugName;
  final CleanupAction cleanupAction;
  final TypeChecker? typeChecker;
  final List<String> typeNames;
  final List<String> typeNameSuffixes;

  String get cleanupMethodName => cleanupAction.methodName;

  bool matchesType(DartType? type) {
    if (type == null) {
      return false;
    }

    final checker = typeChecker;
    if (checker != null && checker.isAssignableFromType(type)) {
      return true;
    }

    if (type is! InterfaceType) {
      return false;
    }

    final typeName = type.element.name;
    if (typeName == null) {
      return false;
    }

    final matchesByName =
        typeNames.contains(typeName) || typeNameSuffixes.any(typeName.endsWith);

    if (!matchesByName) {
      return false;
    }

    return type.getMethod(cleanupMethodName) != null;
  }
}
