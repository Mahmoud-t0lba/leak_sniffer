import 'dart:io';

import 'package:leak_sniffer/src/rules/avoid_unclosed_stream_controller.dart';
import 'package:test/test.dart';

void main() {
  const rule = AvoidUnclosedStreamControllerRule();

  group('avoid_unclosed_stream_controller', () {
    test('reports owned stream controllers without close calls', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('stream_controller_invalid.dart'),
      );

      expect(errors, hasLength(3));
      expect(
        errors.every((error) => error.diagnosticCode.name == rule.code.name),
        isTrue,
      );
    });

    test('accepts injected or cleaned stream controllers', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('stream_controller_valid.dart'),
      );

      expect(errors, isEmpty);
    });
  });
}

File _fixtureFile(String name) {
  return File('${Directory.current.path}/test/fixtures/$name');
}
