# Sunflower — Flutter Migration

> **Status:** Scaffold / in-progress  
> This document describes the Flutter port of the [Android Sunflower](README.md) sample app.

---

## Overview

The Flutter port of Sunflower mirrors the feature set of the original Android Jetpack Compose
application:

| Feature | Android | Flutter |
|---------|---------|---------|
| Plant list | Jetpack Compose + Paging 3 | Flutter + provider |
| Plant detail | Jetpack Compose | Flutter |
| My Garden | Jetpack Compose | Flutter |
| Photo gallery | Unsplash API + Paging 3 | Unsplash API + dio |
| Local database | Room | Drift (SQLite) |
| Navigation | Navigation Compose | go_router |
| DI | Hilt | get_it |
| Theme | Material 3 | Material 3 |

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Flutter SDK | 3.22.0 (stable channel) |
| Dart SDK | 3.3.0 |
| Android Studio / VS Code | Latest stable |
| Xcode (iOS builds) | 15+ |

Install Flutter: https://docs.flutter.dev/get-started/install

---

## Environment Setup

### 1. Clone the repository

```bash
git clone https://github.com/drewtwo/sunflower-android-test.git
cd sunflower-android-test
git checkout ai/feature/flutter-scaffold-project-setup
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the Unsplash API key

Copy the example env file and fill in your key:

```bash
cp .env.example .env
```

Edit `.env`:

```
UNSPLASH_ACCESS_KEY=your_unsplash_access_key_here
```

> **Note:** `.env` is git-ignored. Never commit real API keys.

The key is injected at build time via `--dart-define`:

```bash
flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
```

The CI workflow reads the key from GitHub Actions secrets (`UNSPLASH_ACCESS_KEY`).

---

## Running the App

```bash
# Debug
flutter run

# Release
flutter run --release

# With explicit API key
flutter run --dart-define=UNSPLASH_ACCESS_KEY=abc123
```

---

## Code Generation

Several packages require code generation (drift, json_serializable, retrofit):

```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (re-generates on file save)
flutter pub run build_runner watch --delete-conflicting-outputs
```

Generated files (`*.g.dart`) are **not** committed to version control.

---

## Testing

```bash
# Unit + widget tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests (requires a connected device/emulator)
flutter test integration_test/

# Specific test file
flutter test test/data/plant_test.dart
```

---

## Linting & Formatting

```bash
# Analyze (equivalent to ktlint check)
flutter analyze

# Format (equivalent to ktlint format)
dart format lib/ test/ integration_test/

# Format check only (CI mode)
dart format --output=none --set-exit-if-changed lib/ test/ integration_test/
```

---

## Build Artifacts

```bash
# Android APK (debug)
flutter build apk --debug

# Android APK (release)
flutter build apk --release --dart-define=UNSPLASH_ACCESS_KEY=$UNSPLASH_ACCESS_KEY

# Android App Bundle (release)
flutter build appbundle --release --dart-define=UNSPLASH_ACCESS_KEY=$UNSPLASH_ACCESS_KEY

# iOS (release, requires macOS + Xcode)
flutter build ios --release --dart-define=UNSPLASH_ACCESS_KEY=$UNSPLASH_ACCESS_KEY
```

---

## Project Structure

```
lib/
├── main.dart                   # Entry point
├── app/
│   └── app.dart                # Root widget (MaterialApp + routing)
├── core/
│   ├── constants/
│   │   └── app_constants.dart  # API endpoints, DB name, pagination
│   ├── theme/
│   │   ├── app_colors.dart     # Material 3 color tokens
│   │   ├── app_text_styles.dart# Typography scale
│   │   └── app_theme.dart      # ThemeData (light + dark)
│   └── utils/
│       ├── extensions.dart     # Dart extension methods
│       └── grow_zone_util.dart # USDA grow-zone helper
├── data/
│   ├── datasources/
│   │   ├── app_database.dart   # Drift database definition
│   │   └── unsplash_client.dart# Dio HTTP client
│   ├── models/
│   │   ├── garden_planting.dart
│   │   ├── plant.dart
│   │   ├── unsplash_photo.dart
│   │   └── unsplash_search_response.dart
│   └── repositories/
│       ├── garden_planting_repository.dart
│       ├── plant_repository.dart
│       └── unsplash_repository.dart
├── di/
│   └── service_locator.dart    # get_it registrations
├── features/
│   ├── gallery/                # Unsplash photo gallery
│   ├── garden/                 # My Garden tab
│   ├── home/                   # Bottom-nav host
│   ├── plant_detail/           # Plant detail screen
│   └── plant_list/             # Plant list tab
└── navigation/
    ├── app_routes.dart         # go_router configuration
    └── route_paths.dart        # Route path constants
```

---

## Architecture

The Flutter port follows a **feature-based clean architecture**:

```
UI (Widgets) → ViewModel (ChangeNotifier/provider) → Repository → DataSource
```

- **UI layer:** Flutter widgets, Material 3 components
- **ViewModel layer:** `ChangeNotifier` classes consumed via `provider`
- **Repository layer:** Abstracts local (drift) and remote (dio) data sources
- **Data layer:** Drift DAOs + Dio HTTP client

---

## Migration Notes

- `Room` → `Drift`: Table definitions use `@DataClassName` and `Table` classes instead of
  `@Entity`. DAOs use `@DriftAccessor` instead of `@Dao`.
- `Hilt` → `get_it`: Modules are replaced by `ServiceLocator.setup()` registrations.
- `Navigation Compose` → `go_router`: Routes are defined declaratively with `GoRoute`.
- `Paging 3` → Manual pagination: The gallery uses a simple page-based approach with
  `ScrollController` for infinite scroll.
- `Calendar` → `DateTime`: All date/time fields use Dart's `DateTime` with UTC normalization.
- `Gson` → `json_serializable`: All DTOs use `@JsonSerializable` annotations.

---

## License

```
Copyright 2024 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0
```
