# Flutter Setup Guide — Sunflower

> **Audience:** Developers setting up the Flutter port of the Sunflower app
> for the first time, or returning contributors who need a quick reference.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Environment Setup](#2-environment-setup)
3. [Build Commands](#3-build-commands)
4. [Code Generation](#4-code-generation)
5. [Linting & Formatting](#5-linting--formatting)
6. [Testing](#6-testing)
7. [CI/CD](#7-cicd)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

| Tool | Minimum version | Notes |
|------|----------------|-------|
| Flutter SDK | **3.22.0** (stable) | `flutter --version` |
| Dart SDK | **3.3.0** | Bundled with Flutter |
| Android Studio | Latest stable | Or VS Code with Flutter extension |
| Xcode | 15+ | macOS only, required for iOS builds |
| CocoaPods | 1.13+ | macOS only: `sudo gem install cocoapods` |
| Java | 17 | Required for Android builds |

### Install Flutter

Follow the official guide for your platform:
https://docs.flutter.dev/get-started/install

Verify your installation:

```bash
flutter doctor -v
```

All items should show a green checkmark (or acceptable warnings).

---

## 2. Environment Setup

### 2.1 Clone the repository

```bash
git clone https://github.com/drewtwo/sunflower-android-test.git
cd sunflower-android-test
git checkout ai/feature/flutter-scaffold-project-setup
```

### 2.2 Install Flutter dependencies

```bash
flutter pub get
```

### 2.3 Configure the Unsplash API key

The gallery feature requires a free Unsplash API key.

1. Register at https://unsplash.com/developers
2. Create a new application to obtain an **Access Key**
3. Copy the example env file:

```bash
cp .env.example .env
```

4. Edit `.env` and replace the placeholder:

```
UNSPLASH_ACCESS_KEY=your_actual_key_here
```

> **Security:** `.env` is listed in `.gitignore` and must **never** be
> committed. The key is injected at build time via `--dart-define`.

### 2.4 Run code generation

Several packages (drift, json_serializable, retrofit) require code generation
before the project will compile:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 3. Build Commands

### Run in debug mode

```bash
# Without API key (gallery will show errors)
flutter run

# With API key
flutter run --dart-define=UNSPLASH_ACCESS_KEY=$(grep UNSPLASH_ACCESS_KEY .env | cut -d= -f2)
```

### Run in release mode

```bash
flutter run --release --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

### Build Android APK

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release \
  --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Android App Bundle (for Play Store)

```bash
flutter build appbundle --release \
  --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Build iOS (macOS only)

```bash
# No code signing (CI / simulator)
flutter build ios --release --no-codesign \
  --dart-define=UNSPLASH_ACCESS_KEY=your_key_here

# With code signing (requires Apple Developer account)
flutter build ios --release \
  --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

---

## 4. Code Generation

The following packages generate Dart source files at build time:

| Package | Generated files | Purpose |
|---------|----------------|---------|
| `drift_dev` | `*.g.dart` | Database table classes, DAOs |
| `json_serializable` | `*.g.dart` | `fromJson` / `toJson` methods |
| `retrofit_generator` | `*.g.dart` | HTTP client implementations |

### One-time build

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch mode (re-generates on file save)

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Clean generated files

```bash
flutter pub run build_runner clean
```

> **Note:** Generated `*.g.dart` files are listed in `.gitignore` and are
> **not** committed to version control. Always run code generation after
> pulling changes that modify annotated classes.

---

## 5. Linting & Formatting

### Analyze (static analysis)

Equivalent to running `ktlint check` in the Android project:

```bash
flutter analyze
```

For CI (fails on infos as well as warnings/errors):

```bash
flutter analyze --fatal-infos
```

### Format

Equivalent to running `ktlint format`:

```bash
# Format in-place
dart format lib/ test/ integration_test/

# Check only (CI mode — exits with non-zero if any file would change)
dart format --output=none --set-exit-if-changed lib/ test/ integration_test/
```

### Lint rules

Lint rules are configured in `analysis_options.yaml`. The configuration:
- Extends `package:flutter_lints/flutter.yaml`
- Enables strict type inference (`strict-casts`, `strict-inference`,
  `strict-raw-types`)
- Enables a comprehensive set of `linter` rules mirroring ktlint strictness
- Excludes generated files (`*.g.dart`, `*.freezed.dart`)

---

## 6. Testing

### Unit & widget tests

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter expanded

# Run a specific test file
flutter test test/core/grow_zone_util_test.dart

# Run tests matching a name pattern
flutter test --name "should be watered"
```

### Test coverage

```bash
# Generate coverage data
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Install `lcov` on macOS: `brew install lcov`  
Install `lcov` on Ubuntu: `sudo apt-get install lcov`

### Integration tests

Integration tests run on a connected device or emulator:

```bash
# Run all integration tests
flutter test integration_test/

# Run on a specific device
flutter test integration_test/ -d emulator-5554
```

### Test structure

```
test/
├── test_helpers.dart          # Shared utilities, fixtures, DI helpers
├── core/
│   ├── grow_zone_util_test.dart
│   └── extensions_test.dart
├── data/
│   ├── plant_dao_test.dart
│   ├── garden_planting_dao_test.dart
│   └── unsplash_photo_test.dart
└── features/
    ├── plant_list/
    ├── plant_detail/
    ├── garden/
    └── gallery/

integration_test/
└── app_test.dart              # End-to-end smoke tests
```

---

## 7. CI/CD

The Flutter CI pipeline is defined in `.github/workflows/flutter.yml`.

### Jobs

| Job | Trigger | Description |
|-----|---------|-------------|
| `analyze` | push / PR | Format check + `flutter analyze` |
| `test` | after analyze | Unit & widget tests with coverage |
| `build-android` | after test | Release APK + AAB |
| `build-ios` | after test | iOS release (no-codesign) |

### Secrets

The following GitHub Actions secrets must be configured in the repository:

| Secret | Description |
|--------|-------------|
| `UNSPLASH_ACCESS_KEY` | Unsplash API access key |

### Artifacts

Successful builds upload the following artifacts (retained 14 days):

- `sunflower-flutter-release-apk` — `app-release.apk`
- `sunflower-flutter-release-aab` — `app-release.aab`
- `sunflower-flutter-ios-release` — `Runner.app`

---

## 8. Troubleshooting

### `flutter pub get` fails

```
Could not resolve package: sunflower_flutter
```

Ensure the `name` field in `pubspec.yaml` matches the import prefix used in
Dart files (`sunflower_flutter`).

---

### Build runner fails with `Conflicting outputs`

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

The `--delete-conflicting-outputs` flag removes stale generated files before
regenerating.

---

### `flutter analyze` reports errors in generated files

Generated files (`*.g.dart`) are excluded from analysis via the
`analyzer.exclude` section in `analysis_options.yaml`. If you see errors in
generated files, ensure the exclusion patterns are correct.

---

### iOS build fails: `CocoaPods not installed`

```bash
sudo gem install cocoapods
cd ios && pod install
```

---

### Android build fails: `Java version mismatch`

Ensure Java 17 is active:

```bash
java -version   # should show 17.x
```

If using `jenv`:

```bash
jenv local 17
```

---

### Unsplash gallery shows `401 Unauthorized`

The `UNSPLASH_ACCESS_KEY` is not being injected. Pass it via `--dart-define`:

```bash
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

Or source it from `.env`:

```bash
flutter run --dart-define=UNSPLASH_ACCESS_KEY=$(grep UNSPLASH_ACCESS_KEY .env | cut -d= -f2)
```

---

### `drift` database migration errors

If you change a table schema without adding a migration:

1. Increment `schemaVersion` in `lib/data/datasources/app_database.dart`.
2. Add the migration step to the `onUpgrade` callback in `MigrationStrategy`.
3. For development, you can uninstall the app to reset the database.

---

*For general Flutter questions, see the [Flutter documentation](https://docs.flutter.dev).*  
*For project-specific questions, open an issue or pull request.*
