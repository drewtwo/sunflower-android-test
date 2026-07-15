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

/// Test configuration and setup hooks for the Sunflower Flutter test suite.
///
/// Provides:
/// - [TestConfig] — global test configuration constants
/// - [TestServiceLocator] — DI setup for tests (mirrors Android's
///   `MainTestRunner` / `HiltTestApplication`)
/// - [setUpTestEnvironment] / [tearDownTestEnvironment] — lifecycle hooks
///
/// ## Usage
/// ```dart
/// import 'package:sunflower_flutter/test/test_config.dart';
///
/// void main() {
///   setUpAll(setUpTestEnvironment);
///   tearDownAll(tearDownTestEnvironment);
///
///   // ... tests
/// }
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';

// ---------------------------------------------------------------------------
// Test configuration constants
// ---------------------------------------------------------------------------

/// Global test configuration.
///
/// Mirrors the Android `MainTestRunner` / `HiltTestApplication` pattern
/// for configuring the test environment.
abstract final class TestConfig {
  /// The package name used in test assertions.
  static const String packageName = 'sunflower_flutter';

  /// Default timeout for async test operations.
  static const Duration asyncTimeout = Duration(seconds: 5);

  /// Default timeout for widget test pump-and-settle operations.
  static const Duration pumpTimeout = Duration(seconds: 5);

  /// The number of test plants seeded in the test database.
  static const int testPlantCount = 4;

  /// The number of test garden plantings seeded in the test database.
  static const int testGardenPlantingCount = 1;
}

// ---------------------------------------------------------------------------
// Test DI / service locator
// ---------------------------------------------------------------------------

/// Manages the dependency injection container for tests.
///
/// Mirrors the Android `MainTestRunner` which configures Hilt for testing.
/// In Dart, we use `get_it` and replace production singletons with
/// test-specific implementations.
abstract final class TestServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// The in-memory database instance used during tests.
  static AppDatabase? _testDatabase;

  /// Initialises the DI container with test-specific implementations.
  ///
  /// Call this in `setUpAll` or `setUp` before running tests that depend
  /// on the service locator.
  ///
  /// ```dart
  /// setUpAll(TestServiceLocator.setUp);
  /// ```
  static Future<void> setUp() async {
    // Reset any existing registrations.
    if (_getIt.isRegistered<AppDatabase>()) {
      await _getIt.reset();
    }

    // Create an in-memory database for testing.
    _testDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    // Register the test database.
    _getIt.registerSingleton<AppDatabase>(_testDatabase!);

    // Register repositories backed by the test database.
    _getIt.registerSingleton<PlantRepository>(
      PlantRepository(_testDatabase!.plantDao),
    );
    _getIt.registerSingleton<GardenPlantingRepository>(
      GardenPlantingRepository(_testDatabase!.gardenPlantingDao),
    );
  }

  /// Seeds the test database with standard test fixtures.
  ///
  /// Call after [setUp] to populate the database with known test data.
  static Future<void> seedDatabase() async {
    final db = _testDatabase;
    if (db == null) {
      throw StateError(
        'TestServiceLocator.setUp() must be called before seedDatabase()',
      );
    }

    await db.plantDao.insertPlants([
      PlantsCompanion.insert(
        id: 'sunflower',
        name: 'Sunflower',
        description: 'A bright yellow flower that follows the sun.',
        growZoneNumber: 9,
        wateringInterval: const Value(7),
        imageUrl: const Value('https://example.com/sunflower.jpg'),
      ),
      PlantsCompanion.insert(
        id: 'apple',
        name: 'Apple',
        description: 'A deciduous tree that produces apples.',
        growZoneNumber: 5,
        wateringInterval: const Value(3),
        imageUrl: const Value('https://example.com/apple.jpg'),
      ),
      PlantsCompanion.insert(
        id: 'beet',
        name: 'Beet',
        description: 'A root vegetable with edible leaves.',
        growZoneNumber: 7,
        wateringInterval: const Value(5),
        imageUrl: const Value(''),
      ),
      PlantsCompanion.insert(
        id: 'tomato',
        name: 'Tomato',
        description: 'A red vegetable.',
        growZoneNumber: 1,
        wateringInterval: const Value(2),
        imageUrl: const Value(''),
      ),
    ]);
  }

  /// Tears down the DI container and closes the test database.
  ///
  /// Call this in `tearDownAll` or `tearDown` after tests complete.
  ///
  /// ```dart
  /// tearDownAll(TestServiceLocator.tearDown);
  /// ```
  static Future<void> tearDown() async {
    await _testDatabase?.close();
    _testDatabase = null;
    await _getIt.reset();
  }

  /// Returns the test [AppDatabase] instance.
  ///
  /// Throws [StateError] if [setUp] has not been called.
  static AppDatabase get database {
    final db = _testDatabase;
    if (db == null) {
      throw StateError(
        'TestServiceLocator.setUp() must be called before accessing database',
      );
    }
    return db;
  }
}

// ---------------------------------------------------------------------------
// Lifecycle hooks
// ---------------------------------------------------------------------------

/// Sets up the test environment.
///
/// Call in `setUpAll` for test suites that require DI:
/// ```dart
/// setUpAll(setUpTestEnvironment);
/// ```
Future<void> setUpTestEnvironment() => TestServiceLocator.setUp();

/// Seeds the test database with standard fixtures.
///
/// Call after [setUpTestEnvironment] when tests need pre-populated data:
/// ```dart
/// setUpAll(() async {
///   await setUpTestEnvironment();
///   await seedTestDatabase();
/// });
/// ```
Future<void> seedTestDatabase() => TestServiceLocator.seedDatabase();

/// Tears down the test environment.
///
/// Call in `tearDownAll` to clean up resources:
/// ```dart
/// tearDownAll(tearDownTestEnvironment);
/// ```
Future<void> tearDownTestEnvironment() => TestServiceLocator.tearDown();

// ---------------------------------------------------------------------------
// Flutter test binding initialisation
// ---------------------------------------------------------------------------

/// Ensures the Flutter test binding is initialised.
///
/// Call at the top of `main()` in widget and integration tests:
/// ```dart
/// void main() {
///   ensureTestBindingInitialised();
///   // ...
/// }
/// ```
void ensureTestBindingInitialised() {
  TestWidgetsFlutterBinding.ensureInitialized();
}
