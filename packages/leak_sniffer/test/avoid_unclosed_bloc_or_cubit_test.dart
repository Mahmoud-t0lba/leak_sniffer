import 'dart:io';

import 'package:leak_sniffer/src/rules/avoid_unclosed_bloc_or_cubit.dart';
import 'package:test/test.dart';

void main() {
  const rule = AvoidUnclosedBlocOrCubitRule();

  group('avoid_unclosed_bloc_or_cubit', () {
    test('reports owned blocs and cubits without close calls', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('bloc_or_cubit_invalid.dart'),
      );

      expect(errors, hasLength(2));
      expect(
        errors.every((error) => error.diagnosticCode.name == rule.code.name),
        isTrue,
      );
    });

    test('accepts injected or cleaned blocs and cubits', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('bloc_or_cubit_valid.dart'),
      );

      expect(errors, isEmpty);
    });
  });
}

File _fixtureFile(String name) {
  return File('${Directory.current.path}/test/fixtures/$name');
}
