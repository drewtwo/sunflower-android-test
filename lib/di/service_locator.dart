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

/// Dependency injection setup using [get_it].
///
/// Mirrors the Android Hilt module structure:
/// - [DatabaseModule] → [AppDatabase], [PlantDao], [GardenPlantingDao]
/// - [NetworkModule]  → [Dio], [UnsplashClient]
/// - Repositories     → [PlantRepository], [GardenPlantingRepository],
///                      [UnsplashRepository]
///
/// ## Usage
/// Call [ServiceLocator.setup] once at app startup (before [runApp]):
/// ```dart
/// await ServiceLocator.setup();
/// runApp(const SunflowerApp());
/// ```
///
/// Then resolve dependencies anywhere with:
/// ```dart
/// final db = getIt<AppDatabase>();
/// ```
///
/// ## Testing
/// In tests, call [ServiceLocator.setupForTesting] to register mock
/// implementations instead of real ones.
library;

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';

/// The global [GetIt] instance used throughout the app.
///
/// Prefer accessing dependencies via [getIt]<T>() rather than
/// [GetIt.instance]<T>() for brevity.
final GetIt getIt = GetIt.instance;

/// Configures and registers all application dependencies.
///
/// This class mirrors the Hilt `@Module` pattern from the Android
/// implementation, grouping registrations by layer.
abstract final class ServiceLocator {
  // ---------------------------------------------------------------------------
  // Production setup
  // ---------------------------------------------------------------------------

  /// Registers all production dependencies.
  ///
  /// Must be called once before [runApp]. Awaits async singletons so that
  /// the database is ready before the first frame.
  static Future<void> setup() async {
    _registerDatabase();
    _registerNetwork();
    // Repositories are registered after their dependencies.
    // They will be added here as they are implemented.

    // Wait for all async singletons to complete initialisation.
    await getIt.allReady();
  }

  // ---------------------------------------------------------------------------
  // Test setup
  // ---------------------------------------------------------------------------

  /// Registers test/mock dependencies.
  ///
  /// Call this in `setUp()` / `setUpAll()` in tests. Pass factory functions
  /// that return mock or fake implementations.
  ///
  /// Example:
  /// ```dart
  /// await ServiceLocator.setupForTesting(
  ///   databaseFactory: () => AppDatabase.forTesting(NativeDatabase.memory()),
  /// );
  /// ```
  static Future<void> setupForTesting({
    AppDatabase Function()? databaseFactory,
    Dio Function()? dioFactory,
  }) async {
    // Reset any previously registered instances.
    await getIt.reset();

    // Database — use in-memory by default.
    getIt.registerSingleton<AppDatabase>(
      databaseFactory?.call() ??
          AppDatabase.forTesting(
            // ignore: invalid_use_of_visible_for_testing_member
            inMemoryDatabase(),
          ),
    );

    // DAOs — derived from the database singleton.
    getIt.registerSingleton<PlantDao>(getIt<AppDatabase>().plantDao);
    getIt.registerSingleton<GardenPlantingDao>(
      getIt<AppDatabase>().gardenPlantingDao,
    );

    // Network.
    getIt.registerSingleton<Dio>(dioFactory?.call() ?? createUnsplashDio());
    getIt.registerSingleton<UnsplashClient>(
      UnsplashClient(getIt<Dio>()),
    );

    await getIt.allReady();
  }

  // ---------------------------------------------------------------------------
  // Private registration helpers
  // ---------------------------------------------------------------------------

  /// Registers the [AppDatabase] and its DAOs.
  ///
  /// Mirrors Android's `DatabaseModule`.
  static void _registerDatabase() {
    // AppDatabase — lazy singleton (created on first access).
    getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

    // DAOs — derived from the database singleton.
    getIt.registerLazySingleton<PlantDao>(
      () => getIt<AppDatabase>().plantDao,
    );
    getIt.registerLazySingleton<GardenPlantingDao>(
      () => getIt<AppDatabase>().gardenPlantingDao,
    );
  }

  /// Registers the HTTP client and related network dependencies.
  ///
  /// Mirrors Android's `NetworkModule`.
  static void _registerNetwork() {
    // Dio — lazy singleton with Unsplash configuration.
    getIt.registerLazySingleton<Dio>(createUnsplashDio);

    // UnsplashClient — wraps the Dio instance.
    getIt.registerLazySingleton<UnsplashClient>(
      () => UnsplashClient(getIt<Dio>()),
    );
  }
}
