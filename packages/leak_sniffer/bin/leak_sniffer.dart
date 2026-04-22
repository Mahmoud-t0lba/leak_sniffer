import 'dart:io';

import 'package:leak_sniffer/src/cli/cli_runner.dart';

Future<void> main(List<String> args) async {
  final exitCode = await runLeakSnifferCli(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
