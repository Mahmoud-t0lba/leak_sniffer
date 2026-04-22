import 'dart:io';

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const leakSnifferAnalysisInclude = 'package:leak_sniffer/analysis_options.yaml';
const customLintPluginName = 'custom_lint';

enum LeakSnifferAction { setupOnly, check, watch }

@immutable
class LeakSnifferSetupResult {
  const LeakSnifferSetupResult({
    required this.analysisOptionsPath,
    required this.createdAnalysisOptions,
    required this.addedInclude,
    required this.addedCustomLintPlugin,
    required this.preservedExistingInclude,
  });

  final String analysisOptionsPath;
  final bool createdAnalysisOptions;
  final bool addedInclude;
  final bool addedCustomLintPlugin;
  final bool preservedExistingInclude;

  bool get changed =>
      createdAnalysisOptions || addedInclude || addedCustomLintPlugin;
}

class LeakSnifferSetupException implements Exception {
  LeakSnifferSetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<LeakSnifferSetupResult> ensureLeakSnifferConfigured(
  Directory projectDirectory,
) async {
  final pubspecFile = File('${projectDirectory.path}/pubspec.yaml');
  if (!await pubspecFile.exists()) {
    throw LeakSnifferSetupException(
      'No pubspec.yaml found in ${projectDirectory.path}. Run this command from the root of your Dart or Flutter project.',
    );
  }

  final analysisOptionsFile = File(
    '${projectDirectory.path}/analysis_options.yaml',
  );

  if (!await analysisOptionsFile.exists()) {
    await analysisOptionsFile.writeAsString(
      'include: $leakSnifferAnalysisInclude\n',
    );

    return LeakSnifferSetupResult(
      analysisOptionsPath: analysisOptionsFile.path,
      createdAnalysisOptions: true,
      addedInclude: true,
      addedCustomLintPlugin: false,
      preservedExistingInclude: false,
    );
  }

  final originalContent = await analysisOptionsFile.readAsString();
  if (originalContent.trim().isEmpty) {
    await analysisOptionsFile.writeAsString(
      'include: $leakSnifferAnalysisInclude\n',
    );

    return LeakSnifferSetupResult(
      analysisOptionsPath: analysisOptionsFile.path,
      createdAnalysisOptions: false,
      addedInclude: true,
      addedCustomLintPlugin: false,
      preservedExistingInclude: false,
    );
  }

  final rootNode = loadYamlNode(originalContent);
  if (rootNode is! YamlMap) {
    throw LeakSnifferSetupException(
      'analysis_options.yaml must contain a YAML map at the top level.',
    );
  }

  final include = rootNode['include'];
  final includeValue = include is String ? include : null;

  final analyzerNode = rootNode['analyzer'];
  if (analyzerNode != null && analyzerNode is! YamlMap) {
    throw LeakSnifferSetupException(
      'analysis_options.yaml contains an `analyzer` section that is not a YAML map.',
    );
  }

  final pluginsNode = analyzerNode is YamlMap ? analyzerNode['plugins'] : null;
  final plugins = _readStringList(pluginsNode, fieldName: 'analyzer.plugins');

  final hasLeakSnifferInclude = includeValue == leakSnifferAnalysisInclude;
  final hasPluginsSection = pluginsNode != null;
  final hasCustomLintPlugin = plugins.contains(customLintPluginName);
  final needsInclude = includeValue == null;
  final needsCustomLintPlugin =
      !hasCustomLintPlugin && (!hasLeakSnifferInclude || hasPluginsSection);

  if (!needsInclude && !needsCustomLintPlugin) {
    return LeakSnifferSetupResult(
      analysisOptionsPath: analysisOptionsFile.path,
      createdAnalysisOptions: false,
      addedInclude: false,
      addedCustomLintPlugin: false,
      preservedExistingInclude: includeValue != leakSnifferAnalysisInclude,
    );
  }

  final editor = YamlEditor(originalContent);

  if (needsInclude) {
    editor.update(['include'], leakSnifferAnalysisInclude);
  }

  if (needsCustomLintPlugin) {
    editor.update(['analyzer', 'plugins'], [...plugins, customLintPluginName]);
  }

  await analysisOptionsFile.writeAsString(editor.toString());

  return LeakSnifferSetupResult(
    analysisOptionsPath: analysisOptionsFile.path,
    createdAnalysisOptions: false,
    addedInclude: needsInclude,
    addedCustomLintPlugin: needsCustomLintPlugin,
    preservedExistingInclude:
        includeValue != null && includeValue != leakSnifferAnalysisInclude,
  );
}

Future<int> runCustomLintForProject(
  Directory projectDirectory, {
  required LeakSnifferAction action,
}) async {
  final args = switch (action) {
    LeakSnifferAction.setupOnly => throw ArgumentError.value(
      action,
      'action',
      'setupOnly does not launch custom_lint',
    ),
    LeakSnifferAction.check => const ['run', 'custom_lint'],
    LeakSnifferAction.watch => const ['run', 'custom_lint', '--watch'],
  };

  final process = await Process.start(
    Platform.resolvedExecutable,
    args,
    workingDirectory: projectDirectory.path,
    mode: ProcessStartMode.inheritStdio,
  );

  return process.exitCode;
}

List<String> _readStringList(Object? node, {required String fieldName}) {
  if (node == null) {
    return const [];
  }

  final values = switch (node) {
    YamlList yamlList => yamlList.nodes.map((entry) => entry.value).toList(),
    List<Object?> list => list,
    _ => throw LeakSnifferSetupException(
      '$fieldName must be a YAML list of strings.',
    ),
  };

  if (values.any((entry) => entry is! String)) {
    throw LeakSnifferSetupException(
      '$fieldName must contain only string values.',
    );
  }

  return values.cast<String>();
}
