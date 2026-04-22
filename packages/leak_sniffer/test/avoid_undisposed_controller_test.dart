import 'dart:io';

import 'package:leak_sniffer/src/rules/avoid_undisposed_controller.dart';
import 'package:test/test.dart';

void main() {
  const rule = AvoidUndisposedControllerRule();

  group('avoid_undisposed_controller', () {
    test('reports disposable Flutter resources without cleanup', () async {
      final errors = await rule.testAnalyzeAndRun(
        _workspaceFile(
          'apps/leak_sniffer_example/lint_fixtures/controller_invalid.dart',
        ),
      );

      expect(errors, hasLength(6));
      expect(
        errors.every((error) => error.diagnosticCode.name == rule.code.name),
        isTrue,
      );
    });

    test('accepts controller cleanup in dispose() and close()', () async {
      final errors = await rule.testAnalyzeAndRun(
        _workspaceFile(
          'apps/leak_sniffer_example/lint_fixtures/controller_valid.dart',
        ),
      );

      expect(errors, isEmpty);
    });
  });
}

File _workspaceFile(String relativePath) {
  final workspaceRoot = Directory.current.uri.resolve('../../');
  return File(workspaceRoot.resolve(relativePath).toFilePath());
}
