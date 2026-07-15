# Flutter Test Guide

<!-- Copyright 2024 Google LLC
Licensed under the Apache License, Version 2.0 -->

This guide documents the test structure, patterns, and conventions used in the
Sunflower Flutter test suite. It is the Dart/Flutter equivalent of the Android
test documentation.

## Table of Contents

1. [Test Structure](#1-test-structure)
2. [Unit Test Patterns](#2-unit-test-patterns)
3. [Widget Test Patterns](#3-widget-test-patterns)
4. [Integration Test Setup](#4-integration-test-setup)
5. [Mocking Strategies](#5-mocking-strategies)
6. [Running Tests Locally](#6-running-tests-locally)
7. [Coverage Reporting](#7-coverage-reporting)
8. [CI/CD Integration](#8-cicd-integration)

---

## 1. Test Structure

```
test/                                    # Unit and widget tests
├── test_helpers.dart                    # Shared utilities and factories
├── test_config.dart                     # DI setup, lifecycle hooks
├── fixtures/                            # Test data factories
│   ├── plant_fixtures.dart
│   ├── garden_planting_fixtures.dart
│   └── unsplash_fixtures.dart
├── mocks/                               # Mock implementations
│   ├── mock_repositories.dart
│   └── mock_services.dart
├── core/
│   └── utils/
│       ├── grow_zone_util_test.dart     # GrowZoneUtilTest.kt port
│       └── extensions_test.dart
├── data/
│   ├── models/
│   │   ├── plant_test.dart              # PlantTest.kt port
│   │   └── garden_planting_test.dart   # GardenPlantingTest.kt port
│   ├── datasources/
│   │   └── app_database_test.dart      # PlantDaoTest + GardenPlantingDaoTest port
│   └── repositories/
│       ├── plant_repository_test.dart
│       ├── garden_planting_repository_test.dart
│       └── unsplash_repository_test.dart
└── features/
    ├── plant_list/
    │   ├── providers/plant_list_provider_test.dart
    │   └── widgets/plant_list_screen_test.dart   # PlantListTest.kt port
    ├── plant_detail/
    │   ├── providers/plant_detail_provider_test.dart
    │   └── widgets/plant_detail_screen_test.dart # PlantDetailComposeTest.kt port
    └── garden/
        ├── providers/garden_planting_provider_test.dart
        └── widgets/garden_screen_test.dart       # GardenTest.kt port

integration_test/                        # End-to-end integration tests
├── app_flow_test.dart                   # GardenActivityTest.kt port
├── gallery_pagination_test.dart
└── plant_watering_test.dart
```

### Naming Conventions

| Android | Flutter |
|---------|---------|
| `PlantTest.kt` | `plant_test.dart` |
| `@Test fun testFoo()` | `test('foo', () { ... })` |
| `@Before fun setUp()` | `setUp(() { ... })` |
| `@After fun tearDown()` | `tearDown(() { ... })` |
| `@BeforeClass` | `setUpAll(() { ... })` |
| `@AfterClass` | `tearDownAll(() { ... })` |

---

## 2. Unit Test Patterns

### Basic unit test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/core/utils/grow_zone_util.dart';

void main() {
  group('getZoneForLatitude', () {
    test('returns 13 for latitude 0.0 (equator)', () {
      expect(getZoneForLatitude(0.0), equals(13));
    });

    test('returns 1 for latitude 90.0 (North Pole)', () {
      expect(getZoneForLatitude(90.0), equals(1));
    });
  });
}
```

### Testing async operations

```dart
test('returns plant by id', () async {
  final plant = await repository.getPlantById('sunflower');
  expect(plant, isNotNull);
  expect(plant!.name, equals('Sunflower'));
});
```

### Testing streams

```dart
test('emits plants when stream updates', () async {
  final stream = repository.watchAllPlants();
  final plants = await stream.first;
  expect(plants, isNotEmpty);
});

// Or use emits() matcher:
test('stream emits expected value', () {
  expect(stream, emits(expectedValue));
  expect(stream, emitsInOrder([value1, value2]));
  expect(stream, emitsError(isA<Exception>()));
});
```

### Testing with in-memory database

```dart
import 'package:drift/native.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts and retrieves plant', () async {
    await database.plantDao.insertPlants([
      PlantsCompanion.insert(
        id: 'sunflower',
        name: 'Sunflower',
        description: 'A bright flower.',
        growZoneNumber: 9,
      ),
    ]);

    final plant = await database.plantDao.getPlantById('sunflower');
    expect(plant?.name, equals('Sunflower'));
  });
}
```

---

## 3. Widget Test Patterns

### Basic widget test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/test/test_helpers.dart';

void main() {
  testWidgets('displays plant name', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        PlantCard(plant: testPlant),
      ),
    );

    expect(find.text('Sunflower'), findsOneWidget);
  });
}
```

### Finding widgets

```dart
// By text
find.text('Sunflower')

// By key
find.byKey(const Key('plant_sunflower'))

// By type
find.byType(ElevatedButton)

// By icon
find.byIcon(Icons.add)

// By semantics label (mirrors Android content description)
find.bySemanticsLabel('Add plant')

// By tooltip
find.byTooltip('Gallery Icon')
```

### Interacting with widgets

```dart
// Tap
await tester.tap(find.text('Add to Garden'));
await tester.pump();

// Long press
await tester.longPress(find.byType(ListTile));
await tester.pump();

// Enter text
await tester.enterText(find.byType(TextField), 'sunflower');
await tester.pump();

// Scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pump();
```

### Testing with providers

```dart
testWidgets('shows plants from provider', (WidgetTester tester) async {
  final notifier = PlantListNotifier(mockRepository);

  await tester.pumpWidget(
    wrapWithTheme(
      ChangeNotifierProvider<PlantListNotifier>.value(
        value: notifier,
        child: Consumer<PlantListNotifier>(
          builder: (context, notifier, _) =>
            PlantListScreen(plants: notifier.state.plants),
        ),
      ),
    ),
  );

  await tester.pump();
  expect(find.text('Sunflower'), findsOneWidget);

  notifier.dispose();
});
```

### Pump helpers

```dart
// Pump once (process one frame)
await tester.pump();

// Pump with duration (advance time)
await tester.pump(const Duration(milliseconds: 500));

// Pump and settle (wait for all animations)
await tester.pumpAndSettle();

// Custom settle with timeout
await tester.pumpAndSettle(const Duration(seconds: 5));
```

---

## 4. Integration Test Setup

Integration tests live in `integration_test/` and use the
`integration_test` package.

### Running integration tests

```bash
# Host-side (no device needed, for pure Dart logic)
flutter test integration_test/

# On a connected device/emulator
flutter test integration_test/ -d <device-id>

# Specific test file
flutter test integration_test/app_flow_test.dart
```

### Integration test structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    database = await _createSeededDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('App flow', () {
    test('can add plant to garden', () async {
      final repo = GardenPlantingRepository(database.gardenPlantingDao);
      await repo.addPlanting('sunflower');
      expect(await repo.isPlanted('sunflower'), isTrue);
    });
  });
}
```

---

## 5. Mocking Strategies

### Using mocktail

```dart
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/test/mocks/mock_repositories.dart';

void main() {
  late MockPlantRepository mockRepo;

  setUp(() {
    mockRepo = MockPlantRepository();
  });

  test('delegates to repository', () {
    // Stub
    when(() => mockRepo.watchAllPlants())
        .thenAnswer((_) => Stream.value([testPlant]));

    // Use
    final stream = mockRepo.watchAllPlants();
    expect(stream, emits([testPlant]));

    // Verify
    verify(() => mockRepo.watchAllPlants()).called(1);
  });
}
```

### Available mocks

| Mock Class | Implements |
|-----------|-----------|
| `MockPlantRepository` | `PlantRepository` |
| `MockGardenPlantingRepository` | `GardenPlantingRepository` |
| `MockUnsplashRepository` | `UnsplashRepository` |
| `MockPlantDao` | `PlantDao` |
| `MockGardenPlantingDao` | `GardenPlantingDao` |
| `MockUnsplashClient` | `UnsplashClient` |

### Fake implementations

For tests that need realistic behavior without a real database, use the
in-memory database helper:

```dart
final db = AppDatabase.forTesting(NativeDatabase.memory());
final repo = PlantRepository(db.plantDao);
```

---

## 6. Running Tests Locally

### All tests

```bash
flutter test
```

### Specific test file

```bash
flutter test test/data/models/plant_test.dart
```

### Specific test group

```bash
flutter test --name "PlantExtension.shouldBeWatered"
```

### With verbose output

```bash
flutter test --reporter=expanded
```

### With coverage

```bash
flutter test --coverage
```

### Integration tests

```bash
flutter test integration_test/
```

### Using the coverage script

```bash
# Run tests, generate report, check 60% threshold
./scripts/check_coverage.sh

# Open HTML report after generation
./scripts/check_coverage.sh --open

# Custom threshold
./scripts/check_coverage.sh --threshold 70
```

---

## 7. Coverage Reporting

### Generate coverage report

```bash
flutter test --coverage
genhtml coverage/lcov.info --output-directory coverage/html
open coverage/html/index.html
```

### Coverage targets

See [coverage_baseline.md](../coverage_baseline.md) for detailed targets by
feature area.

| Area | Target |
|------|--------|
| Data models | ≥ 80% |
| Repositories | ≥ 75% |
| Providers | ≥ 70% |
| UI widgets | ≥ 50% |
| Integration | ≥ 40% |
| **Overall** | **≥ 60%** |

---

## 8. CI/CD Integration

Tests run automatically on every PR and push to `main` via:

- **`.github/workflows/flutter-tests.yml`** — unit + widget tests, coverage upload
- **`.github/workflows/coverage.yml`** — coverage gate (60% minimum)

### CI test matrix

| Job | Tests | Coverage |
|-----|-------|---------|
| `unit-tests` | `flutter test` | Uploaded to Codecov |
| `integration-tests` | `flutter test integration_test/` | — |
| `coverage-check` | `flutter test --coverage` | Gate: ≥ 60% |

A PR will be blocked if:
1. Any test fails
2. Coverage drops below 60%
3. `dart format` reports formatting issues
4. `flutter analyze` reports errors
