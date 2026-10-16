import 'dart:io';

import 'package:permission_sync/permission_sync.dart';
import 'package:test/test.dart';

void main() {
  group('runCli', () {
    test('shows help when no arguments are supplied', () {
      final output = StringBuffer();
      final errors = StringBuffer();

      final code = runCli([], out: output, err: errors);

      expect(code, 0);
      expect(output.toString(), contains('Usage:'));
      expect(output.toString(), contains('init'));
      expect(errors.toString(), isEmpty);
    });

    test('shows version', () {
      final output = StringBuffer();

      final code = runCli(['--version'], out: output);

      expect(code, 0);
      expect(output.toString(), contains(packageVersion));
    });

    test('supports short help and version options', () {
      expect(runCli(['-h'], out: StringBuffer()), 0);
      expect(runCli(['-v'], out: StringBuffer()), 0);
    });

    test('rejects unknown commands', () {
      final errors = StringBuffer();

      final code = runCli(['unknown'], out: StringBuffer(), err: errors);

      expect(code, 64);
      expect(errors.toString(), contains('Unknown command'));
    });
  });

  group('findFlutterProjectRoot', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'permission_sync_test_',
      );
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('finds a Flutter project root', () {
      _createFlutterProject(tempDirectory);

      final result = findFlutterProjectRoot(tempDirectory);

      expect(result, isNotNull);
      expect(result!.absolute.path, tempDirectory.absolute.path);
    });

    test('finds the project from a nested directory', () {
      _createFlutterProject(tempDirectory);

      final nestedDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'lib${Platform.pathSeparator}src',
      )..createSync(recursive: true);

      final result = findFlutterProjectRoot(nestedDirectory);

      expect(result, isNotNull);
      expect(result!.absolute.path, tempDirectory.absolute.path);
    });

    test('returns null for a plain Dart project', () {
      _createDartProject(tempDirectory);

      final result = findFlutterProjectRoot(tempDirectory);

      expect(result, isNull);
    });

    test('returns null for an invalid pubspec.yaml', () {
      File('${tempDirectory.path}${Platform.pathSeparator}pubspec.yaml')
          .writeAsStringSync('dependencies: [invalid');

      final result = findFlutterProjectRoot(tempDirectory);

      expect(result, isNull);
    });
  });

  group('initializeProject', () {
    late Directory tempDirectory;
    late StringSink output;
    late StringSink errors;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'permission_sync_init_test_',
      );
      output = StringBuffer();
      errors = StringBuffer();
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test('creates permissions.yaml in a Flutter project', () {
      _createFlutterProject(tempDirectory);

      final exitCode = initializeProject(
        workingDirectory: tempDirectory,
        out: output,
        err: errors,
      );

      final configFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'permissions.yaml',
      );

      expect(exitCode, 0);
      expect(configFile.existsSync(), isTrue);
      expect(configFile.readAsStringSync(), contains('permissions:'));
      expect(configFile.readAsStringSync(), contains('version: 1'));
      expect(output.toString(), contains('Created'));
      expect(errors.toString(), isEmpty);
    });

    test('does not overwrite an existing permissions.yaml', () {
      _createFlutterProject(tempDirectory);

      final configFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'permissions.yaml',
      );

      const originalContent = '# User configuration\ncustom: true\n';
      configFile.writeAsStringSync(originalContent);

      final exitCode = initializeProject(
        workingDirectory: tempDirectory,
        out: output,
        err: errors,
      );

      expect(exitCode, isNot(0));
      expect(configFile.readAsStringSync(), originalContent);
      expect(errors.toString(), contains('already exists'));
    });

    test('rejects a plain Dart project', () {
      _createDartProject(tempDirectory);

      final exitCode = initializeProject(
        workingDirectory: tempDirectory,
        out: output,
        err: errors,
      );

      final configFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'permissions.yaml',
      );

      expect(exitCode, isNot(0));
      expect(configFile.existsSync(), isFalse);
      expect(errors.toString(), contains('No Flutter project found'));
    });

    test('rejects an invalid pubspec.yaml', () {
      File('${tempDirectory.path}${Platform.pathSeparator}pubspec.yaml')
          .writeAsStringSync('dependencies: [invalid');

      final exitCode = initializeProject(
        workingDirectory: tempDirectory,
        out: output,
        err: errors,
      );

      final configFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'permissions.yaml',
      );

      expect(exitCode, isNot(0));
      expect(configFile.existsSync(), isFalse);
      expect(errors.toString(), contains('No Flutter project found'));
    });

    test('creates the configuration from a nested directory', () {
      _createFlutterProject(tempDirectory);

      final nestedDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'lib${Platform.pathSeparator}src',
      )..createSync(recursive: true);

      final exitCode = initializeProject(
        workingDirectory: nestedDirectory,
        out: output,
        err: errors,
      );

      final configFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}'
        'permissions.yaml',
      );

      expect(exitCode, 0);
      expect(configFile.existsSync(), isTrue);
      expect(errors.toString(), isEmpty);
    });
  });
}

void _createFlutterProject(Directory directory) {
  File('${directory.path}${Platform.pathSeparator}pubspec.yaml')
      .writeAsStringSync('''
name: sample_flutter_app
description: A temporary Flutter project for testing.
version: 1.0.0

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
''');
}

void _createDartProject(Directory directory) {
  File('${directory.path}${Platform.pathSeparator}pubspec.yaml')
      .writeAsStringSync('''
name: sample_dart_app
description: A temporary Dart project for testing.
version: 1.0.0

environment:
  sdk: ^3.13.0

dependencies:
  path: ^1.9.0
''');
}
