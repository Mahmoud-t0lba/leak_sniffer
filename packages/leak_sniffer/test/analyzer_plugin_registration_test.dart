import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:leak_sniffer/main.dart';
import 'package:test/test.dart';

void main() {
  test('registers analyzer diagnostics, fixes, and assists', () {
    final registry = _RecordingRegistry();

    plugin.register(registry);

    expect(
      registry.warningRules.map((rule) => rule.name),
      containsAll(<String>[
        'avoid_unclosed_bloc_or_cubit',
        'avoid_unclosed_stream_controller',
        'avoid_uncancelled_timer',
        'avoid_uncancelled_stream_subscription',
        'avoid_undisposed_controller',
      ]),
    );

    expect(
      registry.fixesByCode.keys,
      containsAll(<String>[
        'avoid_unclosed_bloc_or_cubit',
        'avoid_unclosed_stream_controller',
        'avoid_uncancelled_timer',
        'avoid_uncancelled_stream_subscription',
        'avoid_undisposed_controller',
      ]),
    );

    for (final generators in registry.fixesByCode.values) {
      expect(generators, isNotEmpty);
      for (final generator in generators) {
        final producer = generator(
          context: StubCorrectionProducerContext.instance,
        );
        expect(producer.fixKind, isNotNull);
      }
    }

    expect(registry.assists, hasLength(2));
    for (final generator in registry.assists) {
      final producer = generator(
        context: StubCorrectionProducerContext.instance,
      );
      expect(producer.assistKind, isNotNull);
    }
  });
}

class _RecordingRegistry implements PluginRegistry {
  final List<ProducerGenerator> assists = [];
  final Map<String, List<ProducerGenerator>> fixesByCode = {};
  final List<AbstractAnalysisRule> lintRules = [];
  final List<AbstractAnalysisRule> warningRules = [];

  @override
  void registerAssist(ProducerGenerator generator) {
    assists.add(generator);
  }

  @override
  void registerFixForRule(LintCode code, ProducerGenerator generator) {
    fixesByCode.putIfAbsent(code.name, () => []).add(generator);
  }

  @override
  void registerLintRule(AbstractAnalysisRule rule) {
    lintRules.add(rule);
  }

  @override
  void registerWarningRule(AbstractAnalysisRule rule) {
    warningRules.add(rule);
  }
}
