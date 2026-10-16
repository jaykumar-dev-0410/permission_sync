import 'package:permission_sync/src/config/config_validator.dart';
import 'package:test/test.dart';

void main() {
  group('validatePermissionConfig', () {
    test('accepts a valid configuration', () {
      const source = '''
version: 1
permissions:
  location:
    enabled: true
    accuracy: precise
    access: while_in_use
    android_background: false
    ios_background: false
''';

      expect(validatePermissionConfig(source), isEmpty);
    });

    test('accepts a configuration without location', () {
      const source = '''
version: 1
permissions: {}
''';

      expect(validatePermissionConfig(source), isEmpty);
    });

    test('rejects an unsupported version', () {
      const source = '''
version: 2
permissions: {}
''';

      expect(
        validatePermissionConfig(source),
        contains('version must be the integer 1.'),
      );
    });

    test('rejects a non-mapping root', () {
      expect(
        validatePermissionConfig('- one\\n- two'),
        contains('The configuration root must be a YAML mapping.'),
      );
    });

    test('rejects invalid YAML', () {
      final errors = validatePermissionConfig('version: [invalid');

      expect(errors, isNotEmpty);
      expect(errors.first, startsWith('Invalid YAML:'));
    });

    test('rejects an invalid accuracy value', () {
      const source = '''
version: 1
permissions:
  location:
    enabled: true
    accuracy: ultra
    access: while_in_use
    android_background: false
    ios_background: false
''';

      expect(
        validatePermissionConfig(source),
        contains(
          'permissions.location.accuracy must be "approximate" or "precise".',
        ),
      );
    });

    test('rejects a string instead of a boolean', () {
      const source = '''
version: 1
permissions:
  location:
    enabled: "true"
    accuracy: approximate
    access: while_in_use
    android_background: false
    ios_background: false
''';

      expect(
        validatePermissionConfig(source),
        contains('permissions.location.enabled must be a boolean.'),
      );
    });

    test('rejects background location when disabled', () {
      const source = '''
version: 1
permissions:
  location:
    enabled: false
    accuracy: precise
    access: always
    android_background: true
    ios_background: false
''';

      expect(
        validatePermissionConfig(source),
        contains(
          'Background location requires permissions.location.enabled: true.',
        ),
      );
    });

    test('rejects background location without always access', () {
      const source = '''
version: 1
permissions:
  location:
    enabled: true
    accuracy: precise
    access: while_in_use
    android_background: true
    ios_background: false
''';

      expect(
        validatePermissionConfig(source),
        contains(
          'Background location requires permissions.location.access: always.',
        ),
      );
    });

    test('rejects unknown keys', () {
      const source = '''
version: 1
permissons: {}
permissions: {}
''';

      expect(
        validatePermissionConfig(source),
        contains('Unknown key "permissons" in configuration.'),
      );
    });
  });
}
