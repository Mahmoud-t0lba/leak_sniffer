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
  const ResourceSpec({required this.debugName, required this.typeChecker, required this.cleanupAction});

  final String debugName;
  final TypeChecker typeChecker;
  final CleanupAction cleanupAction;

  String get cleanupMethodName => cleanupAction.methodName;

  bool matchesType(DartType? type) {
    return type != null && typeChecker.isAssignableFromType(type);
  }
}
