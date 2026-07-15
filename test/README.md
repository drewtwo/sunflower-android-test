# Sunflower Flutter — Test Quick Reference

<!-- Copyright 2024 Google LLC
Licensed under the Apache License, Version 2.0 -->

Quick reference for common test patterns in the Sunflower Flutter test suite.

## Run Tests

```bash
# All unit + widget tests
flutter test

# With coverage
flutter test --coverage

# Integration tests
flutter test integration_test/

# Coverage check (60% threshold)
./scripts/check_coverage.sh --open
```

## Directory Layout

```
test/
├── test_helpers.dart          # Shared utilities
├── test_config.dart           # DI setup hooks
├── fixtures/                  # Test data
├── mocks/                     # Mock classes
├── core/utils/                # Utility tests
├── data/models/               # Model tests
├── data/datasources/          # Database tests
├── data/repositories/         # Repository tests
└── features/                  # Provider + widget tests

integration_test/
├── app_flow_test.dart         # End-to-end flow
├── gallery_pagination_test.dart
└── plant_watering_test.dart
```

## Common Patterns

### In-memory database

```dart
final db = AppDatabase.forTesting(NativeDatabase.memory());
// ... use db ...
await db.close();
```

### Mock repository

```dart
final mock = MockPlantRepository();
when(() => mock.watchAllPlants())
    .thenAnswer((_) => Stream.value([plant]));
verify(() => mock.watchAllPlants()).called(1);
```

### Widget test

```dart
testWidgets('shows plant name', (tester) async {
  await tester.pumpWidget(wrapWithTheme(MyWidget()));
  expect(find.text('Sunflower'), findsOneWidget);
});
```

### Stream assertion

```dart
expect(stream, emits(value));
expect(stream, emitsInOrder([a, b, c]));
expect(stream, emitsError(isA<Exception>()));
```

### Provider test

```dart
final notifier = PlantListNotifier(mockRepo);
await Future<void>.delayed(Duration.zero); // let stream emit
expect(notifier.state.plants, isNotEmpty);
notifier.dispose();
```

## Android → Flutter Equivalences

| Android | Flutter |
|---------|---------|
| `@Test` | `test(...)` |
| `@Before` | `setUp(...)` |
| `@After` | `tearDown(...)` |
| `assertThat(x, equalTo(y))` | `expect(x, equals(y))` |
| `assertTrue(x)` | `expect(x, isTrue)` |
| `assertFalse(x)` | `expect(x, isFalse)` |
| `assertNull(x)` | `expect(x, isNull)` |
| `assertNotNull(x)` | `expect(x, isNotNull)` |
| `flow.first()` | `await stream.first` |
| `runBlocking { }` | `() async { }` |
| `Room.inMemoryDatabaseBuilder` | `NativeDatabase.memory()` |
| `Mockito.mock(Foo::class)` | `MockFoo()` (mocktail) |
| `whenever(mock.foo()).thenReturn(x)` | `when(() => mock.foo()).thenReturn(x)` |
| `verify(mock).foo()` | `verify(() => mock.foo()).called(1)` |
| `composeTestRule.onNodeWithText("x")` | `find.text('x')` |
| `.assertIsDisplayed()` | `findsOneWidget` |
| `.assertDoesNotExist()` | `findsNothing` |
| `onNodeWithContentDescription("x")` | `find.bySemanticsLabel('x')` |

## Key Files

| File | Purpose |
|------|---------|
| `test/test_helpers.dart` | `wrapWithTheme()`, `TestUtils`, `PlantFixtures` |
| `test/test_config.dart` | `TestServiceLocator`, lifecycle hooks |
| `test/mocks/mock_repositories.dart` | `MockPlantRepository`, etc. |
| `test/mocks/mock_services.dart` | `MockUnsplashClient`, etc. |
| `test/fixtures/plant_fixtures.dart` | `allPlantCompanions`, `sunflowerCompanion` |
| `scripts/check_coverage.sh` | Coverage check script |
| `coverage_baseline.md` | Coverage targets by area |
| `docs/TEST_GUIDE.md` | Full test documentation |
| `docs/TEST_MIGRATION_MAPPING.md` | Android → Flutter mapping |
