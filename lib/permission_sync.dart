import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:permission_sync/src/config/permission_template.dart';

const String packageVersion = '0.1.0';

const String helpMessage = '''
permission_sync - Flutter permission configuration CLI

Usage:
  permission_sync <command> [options]

Commands:
  init       Initialize permission_sync in a Flutter project

Options:
  -h, --help       Show this help message
  -v, --version    Show the package version
''';

int runCli(List<String> arguments, {StringSink? out, StringSink? err}) {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;

  if (arguments.isEmpty ||
      arguments.contains('--help') ||
      arguments.contains('-h')) {
    stdoutSink.writeln(helpMessage);
    return 0;
  }

  if (arguments.length == 1 &&
      (arguments[0] == '--version' || arguments[0] == '-v')) {
    stdoutSink.writeln('permission_sync $packageVersion');
    return 0;
  }

  if (arguments.first == 'init') {
    final remaining = arguments.skip(1).toList();

    if (remaining.isNotEmpty) {
      stderrSink.writeln('Error: Unknown init option.');
      stderrSink.writeln('Usage: permission_sync init');
      return 64;
    }

    return initializeProject(
      workingDirectory: Directory.current,
      out: stdoutSink,
      err: stderrSink,
    );
  }

  stderrSink.writeln('Error: Unknown command or invalid arguments.');
  stderrSink.writeln('Run "permission_sync --help" for usage.');
  return 64;
}

/// Finds the nearest Flutter project root by walking up from [start].
Directory? findFlutterProjectRoot(Directory start) {
  var current = start.absolute;

  while (true) {
    final pubspec = File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    );

    if (pubspec.existsSync()) {
      try {
        final document = loadYaml(pubspec.readAsStringSync());

        if (document is YamlMap) {
          final dependencies = document['dependencies'];
          final devDependencies = document['dev_dependencies'];

          final hasFlutterDependency =
              dependencies is YamlMap && dependencies.containsKey('flutter');

          final hasFlutterTestDependency =
              devDependencies is YamlMap &&
              devDependencies.containsKey('flutter_test');

          if (hasFlutterDependency || hasFlutterTestDependency) {
            return current;
          }
        }
      } on YamlException {
        // An invalid pubspec cannot identify a Flutter project.
      } on FileSystemException {
        // An unreadable pubspec cannot identify a Flutter project.
      }
    }

    final parent = current.parent;

    if (parent.path == current.path) {
      return null;
    }

    current = parent;
  }
}

/// Creates permissions.yaml if it does not already exist.
int initializeProject({
  required Directory workingDirectory,
  required StringSink out,
  required StringSink err,
}) {
  final root = findFlutterProjectRoot(workingDirectory);

  if (root == null) {
    err.writeln(
      'Error: No Flutter project found in this directory or its parents.',
    );
    return 1;
  }

  final configFile = File(
    '${root.path}${Platform.pathSeparator}permissions.yaml',
  );

  if (configFile.existsSync()) {
    err.writeln(
      'Error: permissions.yaml already exists. No files were changed.',
    );
    return 1;
  }

  try {
    configFile.writeAsStringSync(permissionTemplate);
    out.writeln('Created ${configFile.path}');
    return 0;
  } on FileSystemException catch (error) {
    err.writeln('Error: Could not create permissions.yaml: $error');
    return 1;
  }
}
