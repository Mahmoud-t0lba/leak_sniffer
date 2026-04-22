import 'dart:io';
import 'dart:convert';

import 'package:leak_sniffer/src/cli/project_setup.dart';
import 'package:test/test.dart';

void main() {
  group('ensureLeakSnifferConfigured', () {
    test('creates analysis_options.yaml when it does not exist', () async {
      final project = await _createProject();

      final result = await ensureLeakSnifferConfigured(project);
      final analysisOptions = await _readAnalysisOptions(project);
      final pubspec = await _readPubspec(project);

      expect(result.createdAnalysisOptions, isTrue);
      expect(result.addedAnalyzerPlugin, isTrue);
      expect(result.addedCustomLintPlugin, isTrue);
      expect(result.addedCustomLintDependency, isTrue);
      expect(analysisOptions, contains('plugins:'));
      expect(analysisOptions, contains('leak_sniffer:'));
      expect(analysisOptions, contains('path:'));
      expect(
        analysisOptions,
        contains('include: package:leak_sniffer/leak_sniffer.yaml'),
      );
      expect(analysisOptions, contains('plugins:'));
      expect(analysisOptions, contains('- custom_lint'));
      expect(pubspec, contains('dev_dependencies:'));
      expect(pubspec, contains('custom_lint: ^0.8.1'));
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
      final pubspec = await _readPubspec(project);

      expect(result.addedCustomLintPlugin, isTrue);
      expect(result.addedAnalyzerPlugin, isTrue);
      expect(result.addedCustomLintDependency, isTrue);
      expect(result.preservedExistingInclude, isTrue);
      expect(
        analysisOptions,
        contains('include: package:flutter_lints/flutter.yaml'),
      );
      expect(analysisOptions, contains('leak_sniffer:'));
      expect(analysisOptions, contains('plugins:'));
      expect(analysisOptions, contains('- custom_lint'));
      expect(pubspec, contains('custom_lint: ^0.8.1'));
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
      final pubspec = await _readPubspec(project);

      expect(result.addedCustomLintPlugin, isTrue);
      expect(result.addedAnalyzerPlugin, isTrue);
      expect(result.addedCustomLintDependency, isTrue);
      expect(result.addedInclude, isTrue);
      expect(
        analysisOptions,
        contains('include: package:leak_sniffer/leak_sniffer.yaml'),
      );
      expect(analysisOptions, contains('leak_sniffer:'));
      expect(analysisOptions, contains('- some_other_plugin'));
      expect(analysisOptions, contains('- custom_lint'));
      expect(pubspec, contains('custom_lint: ^0.8.1'));
    });

    test('is a no-op when leak_sniffer is already configured', () async {
      final project = await _createProject(
        pubspec: '''
name: sample_project
publish_to: "none"

environment:
  sdk: ^3.11.3

dev_dependencies:
  custom_lint: ^0.8.1
''',
        analysisOptions: '''
plugins:
  leak_sniffer:
    path: /tmp/leak_sniffer

include: package:leak_sniffer/leak_sniffer.yaml

analyzer:
  plugins:
    - custom_lint
''',
      );

      final before = await _readAnalysisOptions(project);
      final result = await ensureLeakSnifferConfigured(project);
      final after = await _readAnalysisOptions(project);

      expect(result.changed, isFalse);
      expect(after, before);
    });

    test(
      'adds the root custom_lint plugin when only the packaged include exists',
      () async {
        final project = await _createProject(
          analysisOptions: '''
include: package:leak_sniffer/leak_sniffer.yaml
''',
        );

        final result = await ensureLeakSnifferConfigured(project);
        final analysisOptions = await _readAnalysisOptions(project);
        final pubspec = await _readPubspec(project);

        expect(result.addedInclude, isFalse);
        expect(result.addedAnalyzerPlugin, isTrue);
        expect(result.addedCustomLintPlugin, isTrue);
        expect(result.addedCustomLintDependency, isTrue);
        expect(analysisOptions, contains('leak_sniffer:'));
        expect(analysisOptions, contains('plugins:'));
        expect(analysisOptions, contains('- custom_lint'));
        expect(pubspec, contains('custom_lint: ^0.8.1'));
      },
    );

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
        final pubspec = await _readPubspec(project);

        expect(result.addedInclude, isTrue);
        expect(result.changed, isTrue);
        expect(result.addedAnalyzerPlugin, isTrue);
        expect(result.addedCustomLintPlugin, isTrue);
        expect(result.addedCustomLintDependency, isTrue);
        expect(
          analysisOptions,
          contains('include: package:leak_sniffer/leak_sniffer.yaml'),
        );
        expect(analysisOptions, contains('plugins:'));
        expect(analysisOptions, contains('- custom_lint'));
        expect(
          analysisOptions,
          isNot(contains('package:leak_sniffer/analysis_options.yaml')),
        );
        expect(analysisOptions, contains('leak_sniffer:'));
        expect(pubspec, contains('custom_lint: ^0.8.1'));
      },
    );

    test('does not duplicate a direct custom_lint dependency', () async {
      final project = await _createProject(
        pubspec: '''
name: sample_project
publish_to: "none"

environment:
  sdk: ^3.11.3

dev_dependencies:
  custom_lint: ^0.8.1
''',
      );

      final result = await ensureLeakSnifferConfigured(project);
      final pubspec = await _readPubspec(project);

      expect(result.addedCustomLintDependency, isFalse);
      expect(
        RegExp(r'custom_lint: \^0\.8\.1').allMatches(pubspec),
        hasLength(1),
      );
    });

    test(
      'keeps the legacy packaged include available for old projects',
      () async {
        final legacyInclude = File(
          '${Directory.current.path}/lib/analysis_options.yaml',
        );

        expect(await legacyInclude.exists(), isTrue);
        expect(
          await legacyInclude.readAsString(),
          contains('include: package:leak_sniffer/leak_sniffer.yaml'),
        );
      },
    );
  });
}

Future<Directory> _createProject({
  String? analysisOptions,
  String? pubspec,
}) async {
  final directory = await Directory.systemTemp.createTemp(
    'leak_sniffer_project_setup_test_',
  );

  await File('${directory.path}/pubspec.yaml').writeAsString(
    pubspec ??
        '''
name: sample_project
publish_to: "none"

environment:
  sdk: ^3.11.3
''',
  );

  await Directory('${directory.path}/.dart_tool').create(recursive: true);
  await File('${directory.path}/.dart_tool/package_config.json').writeAsString(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        {
          'name': 'leak_sniffer',
          'rootUri': Directory.current.uri.toString(),
          'packageUri': 'lib/',
          'languageVersion': '3.11',
        },
      ],
    }),
  );

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

Future<String> _readPubspec(Directory project) {
  return File('${project.path}/pubspec.yaml').readAsString();
}
