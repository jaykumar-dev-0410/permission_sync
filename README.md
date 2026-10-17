# permission_sync

<p align="center">
  <strong>Declarative permission configuration and native permission diagnostics for Flutter projects.</strong>
</p>

<p align="center">
  <em>One readable configuration. Clear platform checks. No silent native-file edits.</em>
</p>

<!-- Add badges after the package is published and CI is configured.
[![pub package](https://img.shields.io/pub/v/permission_sync.svg)](https://pub.dev/packages/permission_sync)
[![Dart](https://img.shields.io/badge/Dart-compatible-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
-->

> **Project status: Early development**
>
> The current implementation supports a minimal YAML schema and Android location permission declaration checks. Other permission categories and platform analyzers described as planned are not implemented yet. APIs, schema, and command output may change before the first stable release.

## Contents

- [Why permission_sync?](#why-permission_sync)
- [Goals and non-goals](#goals-and-non-goals)
- [Current status](#current-status)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Configuration reference](#configuration-reference)
- [Location configuration examples](#location-configuration-examples)
- [CLI reference](#cli-reference)
- [Doctor behavior](#doctor-behavior)
- [Platform permission catalog](#platform-permission-catalog)
- [Platform-specific considerations](#platform-specific-considerations)
- [Troubleshooting](#troubleshooting)
- [Development and testing](#development-and-testing)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [Security and privacy](#security-and-privacy)
- [License](#license)

## Why permission_sync?

Flutter applications can target Android, iOS/iPadOS, web, Windows, macOS, and Linux. Access to device features is configured differently on each platform. Depending on the feature, a project may need native manifest declarations, `Info.plist` usage descriptions, entitlements, package capabilities, browser APIs, runtime authorization, or desktop portal integration.

That setup can be difficult to audit, especially when an app has multiple plugins and native configuration files.

`permission_sync` aims to provide a declarative configuration file and a CLI that checks supported native permission declarations. The goal is to make permission intent easier to review and catch common configuration omissions early.

### Design principles

- **Explicit by default:** permissions are disabled in the generated configuration unless the developer opts in.
- **Read-only diagnostics:** `doctor` reports issues; it does not silently edit native files.
- **Platform-aware:** permission rules are not assumed to be identical across operating systems.
- **Actionable output:** diagnostics should identify the missing declaration or unsupported check.
- **Tested behavior:** supported rules should have positive and negative automated tests.
- **Honest scope:** a static checker should distinguish what it can verify from what requires runtime testing.

## Goals and non-goals

### Goals

- Generate a small, understandable `permissions.yaml`.
- Validate configuration structure and values.
- Detect supported missing native declarations.
- Return meaningful process exit codes for scripts and CI.
- Grow toward a documented cross-platform permission catalog.
- Keep native-file modifications outside the diagnostic workflow.

### Non-goals

`permission_sync doctor` is not intended to:

- Grant permissions to the user or change operating-system settings.
- Replace runtime permission request APIs.
- Guarantee that a permission request will be approved.
- Guarantee that a device supports a hardware feature.
- Replace platform documentation, app-store policy review, or security review.
- Automatically infer every permission required by arbitrary third-party plugins.
- Treat every platform capability as if it were a conventional runtime permission.

## Current status

| Capability | Status | Notes |
|---|---|---|
| CLI help and version | Implemented | Prints usage and package version. |
| Flutter project discovery | Implemented | Walks upward from the working directory. |
| `init` | Implemented | Creates a minimal configuration and refuses to overwrite an existing file. |
| YAML validation | Implemented | Validates schema version and supported location fields. |
| Android manifest location checks | Implemented | Checks coarse, fine, and background location declarations according to the configuration. |
| `uses-permission` | Implemented | Recognizes the standard Android declaration element. |
| `uses-permission-sdk-23` | Implemented | Recognizes the SDK-23 declaration element. |
| Read-only doctor behavior | Implemented | Reports diagnostics without intentionally modifying project files. |
| Camera and microphone checks | Planned | Not currently checked. |
| Photos/media and notifications | Planned | Requires platform/version-specific rules. |
| Bluetooth and nearby devices | Planned | Requires Android-version-aware checks. |
| iOS/iPadOS analyzer | Planned | `Info.plist`, entitlements, capabilities, and related checks. |
| Web analyzer | Planned | Browser API and project capability checks. |
| Windows/macOS/Linux analyzers | Planned | Platform-specific capabilities and sandbox/portal behavior. |

## How it works

At a high level, the CLI follows this process:

```text
Flutter project
      |
      v
Find pubspec.yaml
      |
      v
Read permissions.yaml
      |
      v
Validate configuration
      |
      v
Detect configured platforms
      |
      v
Run supported static checks
      |
      v
Print diagnostics and exit code
```

The intended workflow is:

1. A developer declares which features the app needs in `permissions.yaml`.
2. `validate` checks that the file conforms to the currently supported schema.
3. `doctor` reads the configuration and inspects supported native files.
4. The CLI reports missing declarations or configuration problems.
5. The developer decides how to fix the issue and verifies the result on a device or browser.

The current implementation only performs the implemented checks listed above. The cross-platform flow is the intended architecture, not a claim that all analyzers already exist.

## Requirements

For local development:

- A Dart SDK compatible with the SDK constraint in `pubspec.yaml`.
- A Flutter project for commands that inspect project configuration.
- Android platform files for Android manifest diagnostics.

Check your installed tools:

```bash
dart --version
flutter --version
```

## Installation

### Local development checkout

Until a stable release is published, clone the repository:

```bash
git clone https://github.com/jaykumar-dev-0410/permission_sync.git
cd permission_sync
dart pub get
```

To run the CLI from another Flutter project, pass the path to the checked-out executable:

```bash
dart run /path/to/permission_sync/bin/permission_sync.dart --help
```

PowerShell example:

```powershell
dart run F:\flutter_packages\permission_sync\bin\permission_sync.dart --help
```

After a stable release is published to pub.dev, installation instructions can be updated to use the package directly.

## Quick start

Run these commands from a Flutter project directory or any subdirectory inside it. The CLI searches the current directory and its parents for a Flutter `pubspec.yaml`.

### 1. Initialize the configuration

```bash
dart run permission_sync init
```

Expected result:

```text
Created /path/to/your_flutter_app/permissions.yaml
```

The command creates the file at the Flutter project root. It does not overwrite an existing `permissions.yaml`.

### 2. Review the generated file

The default configuration is deliberately small:

```yaml
version: 1

permissions:
  location:
    enabled: false
    accuracy: approximate
    access: while_in_use
    android_background: false
    ios_background: false
```

Location is disabled by default. You can keep this configuration if the app does not need location.

### 3. Validate the configuration

```bash
dart run permission_sync validate
```

For a valid configuration, the CLI prints:

```text
permissions.yaml is valid.
```

If the configuration is invalid, the command prints validation errors and returns a non-zero exit code.

### 4. Run diagnostics

```bash
dart run permission_sync doctor
```

The current Android analyzer checks location declarations only. If location is disabled or omitted, it does not require location declarations. If location is enabled, the required Android declarations depend on the configuration.

### 5. Inspect the exit code

PowerShell:

```powershell
dart run F:\flutter_packages\permission_sync\bin\permission_sync.dart doctor
"Exit code: $LASTEXITCODE"
```

On shells that expose the last process status as `$?`, inspect that status immediately after the command. Exit codes are useful in CI scripts, but their exact behavior should be verified against the current CLI version.

## Configuration reference

The configuration is intentionally minimal while the schema is under development. Do not add unsupported keys until the validator and corresponding analyzer support them.

### Root fields

| Field | Type | Required | Current behavior |
|---|---|---:|---|
| `version` | Integer | Yes | Must be `1`. |
| `permissions` | Mapping | Yes | Contains supported permission groups. |
| `permissions.location` | Mapping | No | Configures location checks. If omitted, the analyzer requires no location declarations. |

### Location fields

| Field | Type | Allowed values | Default | Current behavior |
|---|---|---|---|---|
| `enabled` | Boolean | `true` / `false` | `false` | When `false`, the analyzer requires no location declarations. |
| `accuracy` | String | `approximate` / `precise` | `approximate` | `precise` adds the fine-location declaration requirement. |
| `access` | String | `while_in_use` / `always` | `while_in_use` | Describes intended access scope and is validated alongside background settings. |
| `android_background` | Boolean | `true` / `false` | `false` | When `true`, the Android analyzer checks for the background-location declaration. |
| `ios_background` | Boolean | `true` / `false` | `false` | Validated by the current configuration schema, but not checked by an iOS analyzer yet. |

The validator also rejects unsupported keys and invalid types or values. For background location, the current schema requires location to be enabled and access to be `always` if either platform background flag is enabled.

### Example: app does not use location

```yaml
version: 1

permissions:
  location:
    enabled: false
    accuracy: approximate
    access: while_in_use
    android_background: false
    ios_background: false
```

This is the generated default.

### Example: approximate foreground location

```yaml
version: 1

permissions:
  location:
    enabled: true
    accuracy: approximate
    access: while_in_use
    android_background: false
    ios_background: false
```

For Android, the current analyzer expects:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Example: precise foreground location

```yaml
version: 1

permissions:
  location:
    enabled: true
    accuracy: precise
    access: while_in_use
    android_background: false
    ios_background: false
```

For Android, the current analyzer expects both coarse and fine declarations:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

The checker verifies declarations; it does not grant location access or prove that runtime authorization has been requested.

### Example: background location intent

```yaml
version: 1

permissions:
  location:
    enabled: true
    accuracy: precise
    access: always
    android_background: true
    ios_background: true
```

The Android analyzer additionally expects:

```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

This setting is only a declaration check. Background location is subject to OS-version rules, runtime authorization flows, foreground-service requirements in applicable scenarios, and app-store policies. The current CLI does not validate all of those requirements and does not yet inspect iOS native configuration.

## CLI reference

Run the commands from a Flutter project directory or a subdirectory of one.

| Command | Purpose | Successful result |
|---|---|---|
| `permission_sync --help` | Show available commands and options. | Help text; exit code `0`. |
| `permission_sync --version` | Show the package version. | Version text; exit code `0`. |
| `permission_sync init` | Create `permissions.yaml`. | File created; exit code `0`. |
| `permission_sync validate` | Validate the configuration file. | Validity message; exit code `0`. |
| `permission_sync doctor` | Validate configuration and run supported native checks. | Diagnostic report; exit code `0` when no issue is found or Android checks are skipped because the Android directory is absent. |

Error conditions such as invalid configuration, missing required files, missing native declarations, or invalid command arguments return non-zero status codes. The CLI uses a usage error code for invalid command arguments.

### `init`

- Locates the nearest Flutter project root.
- Creates `permissions.yaml` at that root.
- Refuses to overwrite an existing file.
- Does not modify native manifests.

### `validate`

- Locates the nearest Flutter project.
- Requires `permissions.yaml`.
- Checks the supported schema and field values.
- Prints errors for invalid configuration.
- Does not inspect native platform files.

### `doctor`

- Validates `permissions.yaml`.
- Detects the Android directory.
- If Android is configured, checks the expected Android manifest.
- Checks the supported location declarations.
- Reports missing declarations.
- Does not modify project files intentionally.

## Doctor behavior

### Android location declaration rules

| Configuration | Required declarations checked by the current analyzer |
|---|---|
| Location omitted | None |
| `enabled: false` | None |
| `enabled: true`, `accuracy: approximate` | `ACCESS_COARSE_LOCATION` |
| `enabled: true`, `accuracy: precise` | `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` |
| `android_background: true` | Also `ACCESS_BACKGROUND_LOCATION` |

Both `uses-permission` and `uses-permission-sdk-23` declaration elements are recognized.

### Example output: configuration valid

```text
permission_sync doctor

Configuration
  ✓ permissions.yaml is valid

Android
  ✓ No missing Android location permissions detected.

No files were modified.
```

### Example output: missing declarations

```text
permission_sync doctor

Configuration
  ✓ permissions.yaml is valid

Android
  ✗ Missing Android permission: android.permission.ACCESS_COARSE_LOCATION
  ✗ Missing Android permission: android.permission.ACCESS_FINE_LOCATION

2 issue(s) found.
No files were modified.
```

Exact output can change as the CLI evolves.

### Projects without Android

If the Flutter project has no `android/` directory, `doctor` skips Android manifest checks. If an `android/` directory exists but the expected manifest is missing, it reports that issue. Other platform analyzers are not implemented yet.

### What static analysis can and cannot prove

A manifest checker can verify that a declaration appears in a file. It cannot, by itself, prove that:

- The user granted permission at runtime.
- The operating system permits the requested behavior for the app's target SDK.
- The device has the relevant hardware.
- A permission request is correctly implemented by a plugin.
- A background service, notification, or device operation will work at runtime.
- App-store policies permit the intended use.

For these cases, developers must also inspect platform documentation, plugin setup instructions, runtime request flows, and device-level behavior.

## Platform permission catalog

The long-term goal is to document supported permission groups in tables rather than putting every possible setting in the generated YAML. The generated file should stay small; this reference can grow as implementation and tests are added.

**Status legend**

- **Implemented:** a check exists in the current CLI.
- **Planned:** a future target; no current analyzer is implied.
- **Platform-specific:** behavior may not map to a conventional runtime permission.

| Category | Android | iOS / iPadOS | Web | Windows | macOS | Linux |
|---|---|---|---|---|---|---|
| Location | Implemented: declaration checks | Planned | Planned | Planned | Planned | Planned |
| Camera | Planned | Planned | Planned | Planned | Planned | Planned |
| Microphone | Planned | Planned | Planned | Planned | Planned | Planned |
| Speech recognition | Planned | Planned | Planned | Planned | Planned | Planned |
| Photos and videos | Planned | Planned | Planned | Planned | Planned | Planned |
| Files and storage | Planned | Planned | Planned | Planned | Planned | Planned |
| Audio media | Planned | Planned | Planned | Planned | Planned | Planned |
| Notifications | Planned | Planned | Planned | Planned | Planned | Planned |
| Background tasks | Planned | Planned | Planned | Planned | Planned | Planned |
| Bluetooth | Planned | Planned | Planned | Planned | Planned | Planned |
| Nearby devices | Planned | Planned | Planned | Planned | Planned | Planned |
| NFC | Planned | Planned | Planned | Planned | Planned | Planned |
| USB / serial | Planned | Planned | Planned | Planned | Planned | Planned |
| Local network | Planned | Planned | Planned | Planned | Planned | Planned |
| Wi-Fi control | Planned | Planned | Planned | Planned | Planned | Planned |
| Contacts | Planned | Planned | Planned | Planned | Planned | Planned |
| Calendar and reminders | Planned | Planned | Planned | Planned | Planned | Planned |
| Health data | Planned | Planned | Planned | Planned | Planned | Planned |
| Motion and sensors | Planned | Planned | Planned | Planned | Planned | Planned |
| Phone and call information | Restricted/platform-specific | Platform-specific | Generally unavailable | Platform-specific | Platform-specific | Platform-specific |
| SMS | Restricted/policy-sensitive | Generally unavailable to third-party apps | Generally unavailable | Platform-specific | Platform-specific | Platform-specific |
| Clipboard | Planned | Planned | Browser-controlled | Planned | Planned | Planned |
| Biometrics | Planned | Planned | WebAuthn/platform-specific | Platform-specific | Platform-specific | Platform-specific |
| Accessibility integration | Special access/platform-specific | Restricted APIs | Browser/OS-dependent | OS-dependent | OS-dependent | Desktop-dependent |
| Overlays | Special access | No direct equivalent | No direct equivalent | Platform-dependent | Platform-dependent | Desktop-dependent |
| Exact alarms | Special access | No direct equivalent | No direct equivalent | No direct equivalent | No direct equivalent | No direct equivalent |
| Battery-optimization exemptions | Special access | No direct equivalent | No direct equivalent | No direct equivalent | No direct equivalent | No direct equivalent |
| App tracking | Platform-specific | Platform-specific | Browser/privacy-dependent | Platform-dependent | Platform-dependent | Platform-dependent |
| Entitlements/capabilities | Planned | Planned | Browser policies | Package capabilities | Entitlements/sandbox | Portals/sandbox |

This catalog is a roadmap, not a guarantee of universal availability. Some features are restricted by OS policy, app-store rules, device hardware, package format, browser support, or third-party plugin implementation.

## Platform-specific considerations

### Android

Android permission requirements can depend on the Android version, `targetSdkVersion`, runtime authorization flow, and whether the feature requires special access. Manifest declarations are only one part of the implementation.

The current analyzer checks location declaration presence only. More categories and version-aware diagnostics are planned.

### iOS and iPadOS

Depending on the feature, native configuration may involve:

- `Info.plist` usage-description keys.
- Entitlements and capabilities.
- Runtime authorization APIs.
- Background modes and feature-specific constraints.

The current release does not analyze iOS native files. The `ios_background` configuration value is validated but not verified against an iOS project.

### Web

Browser permissions are controlled by browser APIs, secure-context requirements, user choices, and permissions policies. A static CLI cannot know whether a user has granted a permission in their browser profile. Future checks should focus on supported API usage and relevant project configuration.

### Windows

Requirements vary with application packaging, capabilities, Windows privacy settings, and the API used. A permission catalog should not assume that a packaged-app capability applies to every Flutter Windows executable.

### macOS

Some resources require usage descriptions, entitlements, sandbox configuration, or user authorization. Requirements depend on the API and how the application is packaged and signed.

### Linux

Linux desktop applications may rely on portals, desktop-environment behavior, sandboxing, device access, or packaging-specific policy. There is no universal permission manifest equivalent for all Linux Flutter applications.

## Troubleshooting

### `No Flutter project found`

Run the command from inside a Flutter project or one of its subdirectories. Confirm that the project's `pubspec.yaml` contains a Flutter dependency or `flutter_test` development dependency.

### `permissions.yaml not found`

Initialize the project:

```bash
dart run permission_sync init
```

If a configuration file already exists elsewhere, make sure it is at the Flutter project root.

### `permissions.yaml already exists`

`init` does not overwrite existing configuration. Review the file and edit it manually if needed.

### `Configuration is invalid`

Run:

```bash
dart run permission_sync validate
```

Read each reported error and correct the field type, allowed value, or unsupported key.

### `Android manifest not found`

If the project is intended to support Android, ensure that the Android platform files exist and the expected file is present at:

```text
android/app/src/main/AndroidManifest.xml
```

If the project does not configure Android, the current doctor skips Android checks when the `android/` directory is absent.

### A permission is reported as missing

Check that the relevant declaration is present in the main manifest and that the YAML requests it. The current analyzer inspects the main manifest file; it does not fully resolve Gradle manifest merging or every library manifest. Verify the merged manifest and test on a device as part of your normal Android build workflow.

### `dart analyze` reports a warning or error

Run:

```bash
dart format lib test
dart analyze
dart test
```

Fix analyzer issues and ensure all tests pass before submitting changes.

## Development and testing

Clone the repository and install dependencies:

```bash
git clone https://github.com/jaykumar-dev-0410/permission_sync.git
cd permission_sync
dart pub get
```

Run formatting, static analysis, and the test suite:

```bash
dart format lib test
dart analyze
dart test
```

### Testing guidelines

When adding a permission group or analyzer rule, include tests for:

1. Valid configuration.
2. Invalid field types and values.
3. Disabled permission groups.
4. Missing required declarations.
5. Correct declarations.
6. Malformed native files.
7. Missing platform files.
8. Exit code and user-facing diagnostic behavior where relevant.

Tests should use temporary directories and fixtures, avoid modifying a developer's real project, and verify that `doctor` remains read-only.

## Contributing

Contributions, issue reports, and design feedback are welcome.

When proposing a new permission group, include:

- The cross-platform configuration fields.
- Platform-specific requirements and exceptions.
- Any OS-version or target-SDK conditions.
- The exact native declarations, entitlements, or capabilities to check.
- Positive and negative tests.
- Known limitations and links to official platform documentation.

Keep configuration minimal and developer-friendly. Prefer a well-documented catalog in this README over generating a huge configuration file full of unused options.

## Roadmap

The project roadmap is:

1. Strengthen Android location diagnostics and regression coverage.
2. Finalize the schema for additional permission groups.
3. Add Android checks for camera, microphone, notifications, media, Bluetooth, contacts, and other carefully scoped categories.
4. Add iOS/iPadOS `Info.plist`, entitlement, and capability checks.
5. Add web-specific checks.
6. Add Windows, macOS, and Linux analyzers where reliable static checks are possible.
7. Add integration tests, CI, examples, and release documentation.
8. Publish a stable release after the schema and supported behavior are sufficiently mature.

The roadmap can change as platform requirements and project priorities evolve.

## Security and privacy

`permission_sync` is intended to help developers review permission configuration. It should not automatically enable permissions that an app does not need.

Follow the principle of least privilege:

- Request only permissions required by the app's user-facing features.
- Keep optional permissions disabled by default.
- Explain why sensitive permissions are needed.
- Request runtime authorization at the point it is needed where appropriate.
- Follow platform and app-store policies for restricted permissions.
- Test denial, revocation, and limited-access cases.
- Avoid collecting or storing permission-related personal data unnecessarily.

## License

A license file has not been specified in this documentation draft. Add the project's chosen open-source license and a `LICENSE` file before publishing a release.
