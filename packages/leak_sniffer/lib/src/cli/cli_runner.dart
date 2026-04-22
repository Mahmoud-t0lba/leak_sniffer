import 'dart:io';

import 'project_setup.dart';

Future<int> runLeakSnifferCli(
  List<String> args, {
  Directory? currentDirectory,
  IOSink? stdoutSink,
  IOSink? stderrSink,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;

  var action = LeakSnifferAction.setupOnly;
  String? projectDirPath;

  for (var index = 0; index < args.length; index++) {
    final argument = args[index];

    if (argument == '--help' || argument == '-h') {
      _printUsage(out);
      return 0;
    }

    if (argument == '--watch') {
      if (action == LeakSnifferAction.check) {
        err.writeln('Use either --check or --watch, not both.');
        return 64;
      }
      action = LeakSnifferAction.watch;
      continue;
    }

    if (argument == '--check') {
      if (action == LeakSnifferAction.watch) {
        err.writeln('Use either --check or --watch, not both.');
        return 64;
      }
      action = LeakSnifferAction.check;
      continue;
    }

    if (argument == '--project-dir') {
      if (index + 1 >= args.length) {
        err.writeln('Missing value after --project-dir.');
        return 64;
      }
      projectDirPath = args[++index];
      continue;
    }

    if (argument.startsWith('--project-dir=')) {
      projectDirPath = argument.substring('--project-dir='.length);
      continue;
    }

    err.writeln('Unknown argument: $argument');
    _printUsage(err);
    return 64;
  }

  if (projectDirPath != null && projectDirPath.trim().isEmpty) {
    err.writeln('The value passed to --project-dir must not be empty.');
    return 64;
  }

  final projectDirectory = projectDirPath == null
      ? (currentDirectory ?? Directory.current)
      : Directory(projectDirPath);

  try {
    final result = await ensureLeakSnifferConfigured(projectDirectory);
    _printSetupSummary(out, result);

    if (action == LeakSnifferAction.setupOnly) {
      out.writeln();
      out.writeln(
        'Next step: run `dart run leak_sniffer --check` or `dart run leak_sniffer --watch`.',
      );
      return 0;
    }

    out.writeln();
    out.writeln(
      action == LeakSnifferAction.watch
          ? 'Starting custom_lint in watch mode...'
          : 'Running custom_lint...',
    );

    return runCustomLintForProject(projectDirectory, action: action);
  } on LeakSnifferSetupException catch (error) {
    err.writeln(error.message);
    return 78;
  }
}

void _printSetupSummary(IOSink sink, LeakSnifferSetupResult result) {
  if (!result.changed) {
    sink.writeln('leak_sniffer is already configured.');
  } else {
    sink.writeln('Configured leak_sniffer successfully.');
  }

  sink.writeln('analysis_options: ${result.analysisOptionsPath}');

  if (result.createdAnalysisOptions) {
    sink.writeln('- created analysis_options.yaml');
  }
  if (result.addedInclude) {
    sink.writeln('- added include: $leakSnifferAnalysisInclude');
  }
  if (result.addedCustomLintPlugin) {
    sink.writeln('- enabled analyzer.plugins: [$customLintPluginName]');
  }
  if (result.preservedExistingInclude) {
    sink.writeln(
      '- preserved your existing include and layered leak_sniffer on top',
    );
  }
}

void _printUsage(IOSink sink) {
  sink.writeln(
    'Usage: dart run leak_sniffer [--check | --watch] [--project-dir <path>]',
  );
  sink.writeln();
  sink.writeln('Configures leak_sniffer automatically in the current project.');
  sink.writeln();
  sink.writeln('Options:');
  sink.writeln(
    '  --check              Configure the project, then run custom_lint once.',
  );
  sink.writeln(
    '  --watch              Configure the project, then run custom_lint --watch.',
  );
  sink.writeln(
    '  --project-dir <dir>  Configure a different project directory.',
  );
  sink.writeln('  --help, -h           Show this message.');
}
