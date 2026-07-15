// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Shared test utilities, mock factories, and setup helpers for the
/// Sunflower Flutter test suite.
///
/// Mirrors the Android test utilities:
/// - `utilities/TestUtils.kt`     → [TestUtils]
/// - `utilities/MainTestRunner`   → [TestServiceLocator]
/// - `MainCoroutineRule.kt`       → [pumpEventQueue] / async helpers
///
/// ## Usage
/// ```dart
/// import 'package:sunflower_flutter/test/test_helpers.dart';
///
/// void main() {
///   late AppDatabase db;
///
///   setUp(() async {
///     db = TestUtils.createInMemoryDatabase();
///   });
///
///   tearDown(() async {
///     await db.close();
///   });
/// }
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sunflower_flutter/core/theme/app_theme.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

// ---------------------------------------------------------------------------
// Database helpers
// ---------------------------------------------------------------------------

/// Provides test utilities for creating and populating test databases.
///
/// Mirrors `utilities/TestUtils.kt` from the Android test suite.
abstract final class TestUtils {
  /// Creates an in-memory [AppDatabase] suitable for unit tests.
  ///
  /// The database is empty (no seed data). Use [insertTestPlants] to
  /// populate it with test fixtures.
  ///
  /// Mirrors `Room.inMemoryDatabaseBuilder(context, AppDatabase::class).build()`.
  static AppDatabase createInMemoryDatabase() =>
      AppDatabase.forTesting(NativeDatabase.memory());

  /// Inserts a list of [PlantsCompanion] fixtures into [db].
  static Future<void> insertTestPlants(
    AppDatabase db,
    List<PlantsCompanion> plants,
  ) =>
      db.plantDao.insertPlants(plants);

  /// Inserts a single [GardenPlantingsCompanion] into [db].
  static Future<int> insertTestGardenPlanting(
    AppDatabase db,
    GardenPlantingsCompanion companion,
  ) =>
      db.gardenPlantingDao.insertGardenPlanting(companion);
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

/// Pre-built [PlantsCompanion] fixtures for use in tests.
///
/// Mirrors the `testPlants` list in the Android `TestUtils.kt`.
abstract final class PlantFixtures {
  /// A sunflower plant fixture (grow zone 9, watering interval 7).
  static final PlantsCompanion sunflower = PlantsCompanion.insert(
    id: 'sunflower',
    name: 'Sunflower',
    description: 'A bright yellow flower.',
    growZoneNumber: 9,
    wateringInterval: const Value(7),
    imageUrl: const Value('https://example.com/sunflower.jpg'),
  );

  /// An apple tree plant fixture (grow zone 5, watering interval 3).
  static final PlantsCompanion apple = PlantsCompanion.insert(
    id: 'apple',
    name: 'Apple',
    description: 'A fruit tree.',
    growZoneNumber: 5,
    wateringInterval: const Value(3),
    imageUrl: const Value('https://example.com/apple.jpg'),
  );

  /// A beet plant fixture (grow zone 7, watering interval 5).
  static final PlantsCompanion beet = PlantsCompanion.insert(
    id: 'beet',
    name: 'Beet',
    description: 'A root vegetable.',
    growZoneNumber: 7,
    wateringInterval: const Value(5),
    imageUrl: const Value(''),
  );

  /// A tomato plant fixture (grow zone 1, watering interval 2).
  ///
  /// Mirrors the `Plant("1", "Tomato", "A red vegetable", 1, 2, "")` fixture
  /// used in the Android `PlantTest`.
  static final PlantsCompanion tomato = PlantsCompanion.insert(
    id: 'tomato',
    name: 'Tomato',
    description: 'A red vegetable.',
    growZoneNumber: 1,
    wateringInterval: const Value(2),
    imageUrl: const Value(''),
  );

  /// Returns all four fixtures as a list.
  static List<PlantsCompanion> get all => [sunflower, apple, beet, tomato];

  /// Returns fixtures for grow zone 9 only.
  static List<PlantsCompanion> get zone9 => [sunflower];

  /// Returns fixtures for grow zone 5 only.
  static List<PlantsCompanion> get zone5 => [apple];
}

/// Pre-built [GardenPlantingsCompanion] fixtures for use in tests.
///
/// Mirrors the `testGardenPlanting` in the Android `TestUtils.kt`.
abstract final class GardenPlantingFixtures {
  /// A reference date for test fixtures.
  ///
  /// Mirrors `testCalendar` set to September 4, 1998 in Android tests.
  static final DateTime testDate = DateTime(1998, 9, 4);

  /// A garden planting for the sunflower plant.
  static GardenPlantingsCompanion sunflowerPlanting({
    DateTime? plantDate,
    DateTime? lastWateringDate,
  }) =>
      newGardenPlanting(
        plantId: 'sunflower',
        plantDate: plantDate ?? testDate,
        lastWateringDate: lastWateringDate ?? testDate,
      );

  /// A garden planting for the apple plant.
  static GardenPlantingsCompanion applePlanting({
    DateTime? plantDate,
    DateTime? lastWateringDate,
  }) =>
      newGardenPlanting(
        plantId: 'apple',
        plantDate: plantDate ?? testDate,
        lastWateringDate: lastWateringDate ?? testDate,
      );
}

// ---------------------------------------------------------------------------
// Widget test helpers
// ---------------------------------------------------------------------------

/// Wraps [widget] in a minimal [MaterialApp] with the Sunflower theme for
/// widget tests.
///
/// Example:
/// ```dart
/// await tester.pumpWidget(wrapWithTheme(const PlantCard(plant: myPlant)));
/// ```
Widget wrapWithTheme(Widget widget) => MaterialApp(
      theme: sunflowerLightTheme,
      home: widget,
    );

/// Wraps [widget] in a [MaterialApp.router] with a simple [GoRouter] for
/// widget tests that require navigation.
///
/// [initialRoute] defaults to `/`.
Widget wrapWithRouter(
  Widget widget, {
  String initialRoute = '/',
}) {
  final GoRouter router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => widget,
      ),
    ],
  );

  return MaterialApp.router(
    theme: sunflowerLightTheme,
    routerConfig: router,
  );
}

// ---------------------------------------------------------------------------
// Async helpers
// ---------------------------------------------------------------------------

/// Pumps the widget tree and settles all pending animations and futures.
///
/// Equivalent to calling [WidgetTester.pumpAndSettle] with a generous
/// timeout. Use this after triggering async operations in widget tests.
Future<void> pumpAndSettle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(seconds: 5));

// ---------------------------------------------------------------------------
// DI helpers
// ---------------------------------------------------------------------------

/// Configures the [ServiceLocator] with an in-memory database for tests.
///
/// Call this in `setUp` / `setUpAll` and pair with [tearDownTestDi] in
/// `tearDown` / `tearDownAll`.
///
/// Mirrors the Android `MainTestRunner` / `HiltTestApplication` pattern.
Future<AppDatabase> setUpTestDi() async {
  final AppDatabase db = TestUtils.createInMemoryDatabase();
  // Additional DI setup will be added here as repositories are implemented.
  return db;
}

/// Closes [db] and resets the DI container.
Future<void> tearDownTestDi(AppDatabase db) async {
  await db.close();
}
