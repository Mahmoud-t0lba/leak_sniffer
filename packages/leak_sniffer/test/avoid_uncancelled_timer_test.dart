import 'dart:io';

import 'package:leak_sniffer/src/rules/avoid_uncancelled_timer.dart';
import 'package:test/test.dart';

void main() {
  const rule = AvoidUncancelledTimerRule();

  group('avoid_uncancelled_timer', () {
    test('reports owned timers without cancel calls', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('timer_invalid.dart'),
      );

      expect(errors, hasLength(2));
      expect(
        errors.every((error) => error.diagnosticCode.name == rule.code.name),
        isTrue,
      );
    });

    test('accepts injected or cleaned timers', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('timer_valid.dart'),
      );

      expect(errors, isEmpty);
    });
  });
}

File _fixtureFile(String name) {
  return File('${Directory.current.path}/test/fixtures/$name');
}
