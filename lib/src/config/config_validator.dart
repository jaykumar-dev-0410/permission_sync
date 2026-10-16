import 'package:yaml/yaml.dart';

/// Validates a permission_sync version 1 YAML configuration.
///
/// Returns an empty list when the configuration is valid.
List<String> validatePermissionConfig(String source) {
  final errors = <String>[];
  dynamic document;

  try {
    document = loadYaml(source);
  } on YamlException catch (error) {
    return ['Invalid YAML: ${error.message}'];
  }

  if (document is! YamlMap) {
    return ['The configuration root must be a YAML mapping.'];
  }

  _checkAllowedKeys(
    document,
    const {'version', 'permissions'},
    'configuration',
    errors,
  );

  final version = document['version'];

  if (version is! int || version != 1) {
    errors.add('version must be the integer 1.');
  }

  final permissions = document['permissions'];

  if (permissions is! YamlMap) {
    errors.add('permissions must be a YAML mapping.');
    return errors;
  }

  _checkAllowedKeys(permissions, const {'location'}, 'permissions', errors);

  if (permissions.containsKey('location')) {
    _validateLocation(permissions['location'], errors);
  }

  return errors;
}

void _validateLocation(dynamic value, List<String> errors) {
  if (value is! YamlMap) {
    errors.add('permissions.location must be a YAML mapping.');
    return;
  }

  _checkAllowedKeys(
    value,
    const {
      'enabled',
      'accuracy',
      'access',
      'android_background',
      'ios_background',
    },
    'permissions.location',
    errors,
  );

  final enabled = value['enabled'];
  final accuracy = value['accuracy'];
  final access = value['access'];
  final androidBackground = value['android_background'];
  final iosBackground = value['ios_background'];

  if (enabled is! bool) {
    errors.add('permissions.location.enabled must be a boolean.');
  }

  if (accuracy is! String ||
      !const {'approximate', 'precise'}.contains(accuracy)) {
    errors.add(
      'permissions.location.accuracy must be '
      '"approximate" or "precise".',
    );
  }

  if (access is! String || !const {'while_in_use', 'always'}.contains(access)) {
    errors.add(
      'permissions.location.access must be '
      '"while_in_use" or "always".',
    );
  }

  if (androidBackground is! bool) {
    errors.add('permissions.location.android_background must be a boolean.');
  }

  if (iosBackground is! bool) {
    errors.add('permissions.location.ios_background must be a boolean.');
  }

  final requestsBackground = androidBackground == true || iosBackground == true;

  if (requestsBackground && enabled != true) {
    errors.add(
      'Background location requires permissions.location.enabled: true.',
    );
  }

  if (requestsBackground && access != 'always') {
    errors.add(
      'Background location requires permissions.location.access: always.',
    );
  }
}

void _checkAllowedKeys(
  YamlMap map,
  Set<String> allowedKeys,
  String path,
  List<String> errors,
) {
  for (final key in map.keys) {
    if (key is! String || !allowedKeys.contains(key)) {
      errors.add('Unknown key "$key" in $path.');
    }
  }
}
