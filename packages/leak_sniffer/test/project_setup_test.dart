import 'dart:io';

import 'package:leak_sniffer/src/cli/project_setup.dart';
import 'package:test/test.dart';

void main() {
  group('ensureLeakSnifferConfigured', () {
    test('creates analysis_options.yaml when it does not exist', () async {
      final project = await _createProject();

      final result = await ensureLeakSnifferConfigured(project);
      final analysisOptions = await _readAnalysisOptions(project);

      expect(result.createdAnalysisOptions, isTrue);
      expect(
        analysisOptions,
        contains('include: package:leak_sniffer/leak_sniffer.yaml'),
      );
    });

    test('preserves an existing include and adds custom_lint plugin', () async {
      final project = await _createProject(
        analysisOptions: '''
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
''',
      );

      final result = await ensureLeakSnifferConfigured(project);
      final analysisOptions = await _readAnalysisOptions(project);

      expect(result.addedCustomLintPlugin, isTrue);
      expect(result.preservedExistingInclude, isTrue);
      expect(
        analysisOptions,
        contains('include: package:flutter_lints/flutter.yaml'),
      );
      expect(analysisOptions, contains('plugins:'));
      expect(analysisOptions, contains('- custom_lint'));
    });

    test('adds custom_lint to an existing analyzer plugins list', () async {
      final project = await _createProject(
        analysisOptions: '''
include: package:leak_sniffer/analysis_options.yaml

analyzer:
  plugins:
    - some_other_plugin
''',
      );

      final result = await ensureLeakSnifferConfigured(project);
      final analysisOptions = await _readAnalysisOptions(project);

      expect(result.addedCustomLintPlugin, isTrue);
      expect(result.addedInclude, isTrue);
      expect(
        analysisOptions,
        contains('include: package:leak_sniffer/leak_sniffer.yaml'),
      );
      expect(analysisOptions, contains('- some_other_plugin'));
      expect(analysisOptions, contains('- custom_lint'));
    });

    test('is a no-op when leak_sniffer is already configured', () async {
      final project = await _createProject(
        analysisOptions: '''
include: package:leak_sniffer/leak_sniffer.yaml
''',
      );

      final before = await _readAnalysisOptions(project);
      final result = await ensureLeakSnifferConfigured(project);
      final after = await _readAnalysisOptions(project);

      expect(result.changed, isFalse);
      expect(after, before);
    });

    test(
      'migrates the legacy packaged include to the new include path',
      () async {
        final project = await _createProject(
          analysisOptions: '''
include: package:leak_sniffer/analysis_options.yaml
''',
        );

        final result = await ensureLeakSnifferConfigured(project);
        final analysisOptions = await _readAnalysisOptions(project);

        expect(result.addedInclude, isTrue);
        expect(result.changed, isTrue);
        expect(result.addedCustomLintPlugin, isFalse);
        expect(
          analysisOptions,
          contains('include: package:leak_sniffer/leak_sniffer.yaml'),
        );
        expect(
          analysisOptions,
          isNot(contains('package:leak_sniffer/analysis_options.yaml')),
        );
      },
    );
  });
}

Future<Directory> _createProject({String? analysisOptions}) async {
  final directory = await Directory.systemTemp.createTemp(
    'leak_sniffer_project_setup_test_',
  );

  await File('${directory.path}/pubspec.yaml').writeAsString('''
name: sample_project
publish_to: "none"

environment:
  sdk: ^3.11.3
''');

  if (analysisOptions != null) {
    await File(
      '${directory.path}/analysis_options.yaml',
    ).writeAsString(analysisOptions);
  }

  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  return directory;
}

Future<String> _readAnalysisOptions(Directory project) {
  return File('${project.path}/analysis_options.yaml').readAsString();
}
