import 'dart:io';

import 'package:leak_sniffer/src/rules/avoid_uncancelled_stream_subscription.dart';
import 'package:test/test.dart';

void main() {
  const rule = AvoidUncancelledStreamSubscriptionRule();

  group('avoid_uncancelled_stream_subscription', () {
    test('reports owned subscriptions without cancel calls', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('stream_subscription_invalid.dart'),
      );

      expect(errors, hasLength(2));
      expect(
        errors.every((error) => error.diagnosticCode.name == rule.code.name),
        isTrue,
      );
    });

    test('accepts injected or cleaned subscriptions', () async {
      final errors = await rule.testAnalyzeAndRun(
        _fixtureFile('stream_subscription_valid.dart'),
      );

      expect(errors, isEmpty);
    });
  });
}

File _fixtureFile(String name) {
  return File('${Directory.current.path}/test/fixtures/$name');
}
