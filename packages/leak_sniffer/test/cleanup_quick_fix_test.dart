import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:leak_sniffer/src/rules/avoid_unclosed_bloc_or_cubit.dart';
import 'package:leak_sniffer/src/rules/avoid_unclosed_stream_controller.dart';
import 'package:leak_sniffer/src/rules/avoid_uncancelled_stream_subscription.dart';
import 'package:leak_sniffer/src/rules/avoid_uncancelled_timer.dart';
import 'package:leak_sniffer/src/rules/avoid_undisposed_controller.dart';
import 'package:test/test.dart';

void main() {
  group('cleanup quick fixes', () {
    test('adds cancel() to an existing dispose() for Timer', () async {
      final result = await _runSingleFix(
        const AvoidUncancelledTimerRule(),
        _fixtureFile('timer_fix_existing_dispose.dart'),
      );

      expect(result.message, 'Add _timer.cancel(); to dispose()');
      expect(
        result.output,
        contains(
          'void dispose() {\n'
          '    _timer.cancel();\n'
          '  }',
        ),
      );
    });

    test('creates dispose() for an unclosed StreamController', () async {
      final result = await _runSingleFix(
        const AvoidUnclosedStreamControllerRule(),
        _fixtureFile('stream_controller_fix_create_dispose.dart'),
      );

      expect(result.message, 'Create dispose() and call _controller.close();');
      expect(
        result.output,
        contains(
          'void dispose() {\n'
          '    _controller.close();\n'
          '  }',
        ),
      );
    });

    test(
      'adds cancel() before return super.close() in Cubit classes',
      () async {
        final result = await _runSingleFix(
          const AvoidUncancelledStreamSubscriptionRule(),
          _fixtureFile('stream_subscription_fix_cubit_close.dart'),
        );

        expect(result.message, 'Add _subscription.cancel(); to close()');
        expect(
          result.output,
          contains(
            'Future<void> close() {\n'
            '    _subscription.cancel();\n'
            '    return super.close();\n'
            '  }',
          ),
        );
      },
    );

    test(
      'creates dispose() with super.dispose() for Bloc/Cubit fields in State',
      () async {
        final result = await _runSingleFix(
          const AvoidUnclosedBlocOrCubitRule(),
          _fixtureFile('bloc_field_fix_state_dispose.dart'),
        );

        expect(result.message, 'Create dispose() and call _cubit.close();');
        expect(
          result.output,
          contains(
            '@override\n'
            '  void dispose() {\n'
            '    _cubit.close();\n'
            '    super.dispose();\n'
            '  }',
          ),
        );
      },
    );

    test(
      'creates dispose() with super.dispose() for controller fields in State',
      () async {
        final result = await _runSingleFix(
          const AvoidUndisposedControllerRule(),
          _fixtureFile('controller_fix_state_dispose.dart'),
        );

        expect(
          result.message,
          'Create dispose() and call _controller.dispose();',
        );
        expect(
          result.output,
          contains(
            '@override\n'
            '  void dispose() {\n'
            '    _controller.dispose();\n'
            '    super.dispose();\n'
            '  }',
          ),
        );
      },
    );

    test(
      'creates onClose() with super.onClose() for GetX-like controllers',
      () async {
        final result = await _runSingleFix(
          const AvoidUndisposedControllerRule(),
          _fixtureFile('controller_fix_getx_on_close.dart'),
        );

        expect(
          result.message,
          'Create onClose() and call _controller.dispose();',
        );
        expect(
          result.output,
          contains(
            '@override\n'
            '  void onClose() {\n'
            '    _controller.dispose();\n'
            '    super.onClose();\n'
            '  }',
          ),
        );
      },
    );
  });
}

Future<_FixResult> _runSingleFix(DartLintRule rule, File file) async {
  final errors = await rule.testAnalyzeAndRun(file);
  expect(errors, hasLength(1));

  final fix = rule.getFixes().single as DartFix;
  final changes = await fix.testAnalyzeAndRun(file, errors.single, errors);
  expect(changes, hasLength(1));

  final change = changes.single.change;
  final fileEdit = change.edits.singleWhere((edit) => edit.file == file.path);
  final output = SourceEdit.applySequence(
    file.readAsStringSync(),
    fileEdit.edits,
  );

  return _FixResult(message: change.message, output: output);
}

File _fixtureFile(String name) {
  return File('${Directory.current.path}/test/fixtures/$name');
}

class _FixResult {
  const _FixResult({required this.message, required this.output});

  final String message;
  final String output;
}
