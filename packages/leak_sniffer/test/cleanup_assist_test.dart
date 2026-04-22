import 'dart:io';

import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:leak_sniffer/src/analysis/leak_resource_analyzers.dart';
import 'package:leak_sniffer/src/fixes/add_lifecycle_cleanup_fix.dart';
import 'package:leak_sniffer/src/rules/avoid_unclosed_bloc_or_cubit.dart';
import 'package:leak_sniffer/src/rules/avoid_unclosed_stream_controller.dart';
import 'package:leak_sniffer/src/rules/avoid_uncancelled_timer.dart';
import 'package:leak_sniffer/src/rules/avoid_undisposed_controller.dart';
import 'package:test/test.dart';

void main() {
  group('cleanup assists', () {
    test('offers cancel() from context actions on Timer fields', () async {
      final result = await _runAssist(
        AddLifecycleCleanupAssist(
          resourceAnalyzer: AvoidUncancelledTimerRule.resourceAnalyzer,
        ),
        _fixtureFile('timer_fix_existing_dispose.dart'),
        'Timer _timer',
      );

      expect(result.message, 'Add _timer.cancel(); to dispose()');
      expect(result.output, contains('_timer.cancel();'));
    });

    test(
      'offers close() from context actions on StreamController fields',
      () async {
        final result = await _runAssist(
          AddLifecycleCleanupAssist(
            resourceAnalyzer:
                AvoidUnclosedStreamControllerRule.resourceAnalyzer,
          ),
          _fixtureFile('stream_controller_fix_create_dispose.dart'),
          'StreamController<int> _controller',
        );

        expect(
          result.message,
          'Create dispose() and call _controller.close();',
        );
        expect(result.output, contains('_controller.close();'));
      },
    );

    test(
      'offers close() from context actions on bloc or cubit fields',
      () async {
        final result = await _runAssist(
          AddLifecycleCleanupAssist(
            resourceAnalyzer: AvoidUnclosedBlocOrCubitRule.resourceAnalyzer,
          ),
          _fixtureFile('bloc_field_fix_state_dispose.dart'),
          'SearchCubit _cubit',
        );

        expect(result.message, 'Create dispose() and call _cubit.close();');
        expect(result.output, contains('_cubit.close();'));
      },
    );

    test(
      'offers dispose() from context actions on GetX-owned controllers',
      () async {
        final result = await _runAssist(
          AddLifecycleCleanupAssist(
            resourceAnalyzer: AvoidUndisposedControllerRule.resourceAnalyzer,
          ),
          _fixtureFile('controller_fix_getx_on_close.dart'),
          'SearchController _controller',
        );

        expect(
          result.message,
          'Create onClose() and call _controller.dispose();',
        );
        expect(result.output, contains('_controller.dispose();'));
        expect(result.output, contains('void onClose() {'));
      },
    );

    test(
      'offers a fix-all context action for all leaking resources in a class',
      () async {
        final result = await _runAssist(
          AddAllLifecycleCleanupAssist(
            resourceAnalyzer: allLeakSnifferResourceAnalyzer,
          ),
          _fixtureFile('multi_resource_fix_all.dart'),
          'DashboardState',
        );

        expect(result.message, 'Fix all missing cleanups in this class');
        expect(result.output, contains('_timer.cancel();'));
        expect(result.output, contains('_controller.dispose();'));
        expect(result.output, contains('_subscription.cancel();'));
      },
    );
  });
}

Future<_AssistResult> _runAssist(
  DartAssist assist,
  File file,
  String targetText,
) async {
  final source = file.readAsStringSync();
  final offset = source.indexOf(targetText);
  expect(offset, isNonNegative);

  final changes = await assist.testAnalyzeAndRun(file, SourceRange(offset, 0));
  expect(changes, hasLength(1));

  final change = changes.single.change;
  final fileEdit = change.edits.singleWhere((edit) => edit.file == file.path);
  final output = SourceEdit.applySequence(source, fileEdit.edits);

  return _AssistResult(message: change.message, output: output);
}

File _fixtureFile(String name) {
  return File('${Directory.current.path}/test/fixtures/$name');
}

class _AssistResult {
  const _AssistResult({required this.message, required this.output});

  final String message;
  final String output;
}
