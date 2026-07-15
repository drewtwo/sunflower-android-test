# Flutter Test Coverage Baseline

<!-- Copyright 2024 Google LLC
Licensed under the Apache License, Version 2.0 -->

This document establishes the coverage targets for the Sunflower Flutter test
suite and provides a comparison with the Android baseline.

## Overall Target

| Metric | Target | Android Baseline |
|--------|--------|-----------------|
| Line coverage | **≥ 60%** | ~55% (instrumented + unit) |
| Branch coverage | ≥ 50% | ~45% |

The 60% target intentionally exceeds the Android baseline to take advantage of
Dart's superior testability (pure unit tests without instrumentation overhead).

---

## Coverage Targets by Feature Area

### Data Layer

| Component | Target | Notes |
|-----------|--------|-------|
| `lib/data/models/` | **≥ 80%** | Pure data classes — easy to test |
| `lib/data/datasources/app_database.dart` | **≥ 75%** | Drift DAO queries |
| `lib/data/repositories/` | **≥ 75%** | Repository delegation |
| `lib/data/datasources/unsplash_client.dart` | **≥ 60%** | HTTP client |

### Core Utilities

| Component | Target | Notes |
|-----------|--------|-------|
| `lib/core/utils/grow_zone_util.dart` | **≥ 95%** | Pure function — mirrors Android 100% |
| `lib/core/utils/extensions.dart` | **≥ 90%** | Extension methods |
| `lib/core/utils/date_time_converter.dart` | **≥ 80%** | Drift type converter |
| `lib/core/constants/` | **≥ 70%** | Constants |

### State Management (Providers)

| Component | Target | Notes |
|-----------|--------|-------|
| `lib/features/plant_list/providers/` | **≥ 70%** | PlantListNotifier |
| `lib/features/plant_detail/providers/` | **≥ 70%** | PlantDetailNotifier |
| `lib/features/garden/providers/` | **≥ 70%** | GardenPlantingNotifier |
| `lib/features/gallery/providers/` | **≥ 60%** | GalleryProvider |

### UI Widgets

| Component | Target | Notes |
|-----------|--------|-------|
| Widget tests (overall) | **≥ 50%** | Mirrors Android Compose test coverage |
| Plant list screen | **≥ 55%** | Item display, filtering |
| Plant detail screen | **≥ 55%** | Add/remove, gallery icon |
| Garden screen | **≥ 55%** | Empty state, planted items |

### Integration Tests

| Component | Target | Notes |
|-----------|--------|-------|
| End-to-end flows | **≥ 40%** | App flow, watering, gallery |
| Database operations | **≥ 70%** | Real in-memory DB |

---

## Android → Flutter Coverage Comparison

| Android Test Class | Android Coverage | Flutter Equivalent | Flutter Target |
|-------------------|-----------------|-------------------|----------------|
| `PlantTest.kt` | ~100% | `plant_test.dart` | ≥ 95% |
| `GardenPlantingTest.kt` | ~100% | `garden_planting_test.dart` | ≥ 95% |
| `GrowZoneUtilTest.kt` | ~100% | `grow_zone_util_test.dart` | ≥ 95% |
| `PlantDaoTest.kt` | ~90% | `app_database_test.dart` | ≥ 85% |
| `GardenPlantingDaoTest.kt` | ~90% | `app_database_test.dart` | ≥ 85% |
| `PlantListTest.kt` | ~70% | `plant_list_screen_test.dart` | ≥ 65% |
| `GardenTest.kt` | ~70% | `garden_screen_test.dart` | ≥ 65% |
| `PlantDetailComposeTest.kt` | ~75% | `plant_detail_screen_test.dart` | ≥ 70% |
| `GardenActivityTest.kt` | ~60% | `app_flow_test.dart` | ≥ 55% |

---

## Excluded from Coverage

The following files are excluded from coverage calculations because they
contain only generated code or configuration:

```
**/*.g.dart          # drift/json_serializable generated code
**/*.freezed.dart    # freezed generated code
**/generated/**      # any generated directory
```

---

## Running Coverage Locally

```bash
# Quick check with default 60% threshold
./scripts/check_coverage.sh

# Check with custom threshold
./scripts/check_coverage.sh --threshold 70

# Generate and open HTML report
./scripts/check_coverage.sh --open

# Manual steps
flutter test --coverage
genhtml coverage/lcov.info --output-directory coverage/html
open coverage/html/index.html
```

---

## CI Integration

Coverage is checked automatically on every PR via:
- `.github/workflows/flutter-tests.yml` — runs tests and uploads to Codecov
- `.github/workflows/coverage.yml` — enforces 60% threshold as a CI gate

A PR will fail if coverage drops below 60%.

---

## Improvement Roadmap

1. **Phase 1 (current):** Establish 60% baseline with unit + widget tests
2. **Phase 2:** Add widget tests for real screen implementations → target 65%
3. **Phase 3:** Add integration tests for navigation flows → target 70%
4. **Phase 4:** Add golden tests for UI components → target 75%
