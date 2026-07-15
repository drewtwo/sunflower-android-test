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
/// - `DatabaseModule.kt` → [AppDatabase], [PlantDao], [GardenPlantingDao]
/// - `NetworkModule.kt`  → [Dio], [UnsplashClient], [UnsplashService]
/// - Repositories        → [PlantRepository], [GardenPlantingRepository],
///                         [UnsplashRepository]
///
/// ## Android → Dart mapping
/// | Android (Hilt)                    | Dart (get_it)                       |
/// |-----------------------------------|-------------------------------------|
/// | `@Singleton` + `@Inject`          | `registerLazySingleton<T>(...)`     |
/// | `@HiltViewModel`                  | Provider/StateNotifier (in features)|
/// | `@Provides @Singleton`            | `registerLazySingleton<T>(...)`     |
/// | `@InstallIn(SingletonComponent)`  | top-level `getIt` instance          |
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
/// final plantRepo = getIt<PlantRepository>();
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
import 'package:sunflower_flutter/data/datasources/unsplash_service.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';
import 'package:sunflower_flutter/data/repositories/unsplash_repository.dart';

/// The global [GetIt] instance used throughout the app.
///
/// Prefer accessing dependencies via [getIt]<T>() rather than
/// [GetIt.instance]<T>() for brevity.
final GetIt getIt = GetIt.instance;

/// Configures and registers all application dependencies.
///
/// This class mirrors the Hilt `@Module` pattern from the Android
/// implementation, grouping registrations by layer:
/// 1. Database layer (AppDatabase + DAOs)
/// 2. Network layer (Dio + UnsplashClient + UnsplashService)
/// 3. Repository layer (PlantRepository, GardenPlantingRepository, UnsplashRepository)
abstract final class ServiceLocator {
  // ---------------------------------------------------------------------------
  // Production setup
  // ---------------------------------------------------------------------------

  /// Registers all production dependencies.
  ///
  /// Must be called once before [runApp]. Awaits async singletons so that
  /// the database is ready before the first frame.
  ///
  /// Mirrors the Hilt application component initialization that happens
  /// automatically in Android via `@HiltAndroidApp`.
  static Future<void> setup() async {
    _registerDatabase();
    _registerNetwork();
    _registerRepositories();

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
  /// Mirrors the Android `HiltTestApplication` + `@UninstallModules` pattern
  /// used in instrumented tests.
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
    // Mirrors `Room.inMemoryDatabaseBuilder(context, AppDatabase::class).build()`
    final AppDatabase db = databaseFactory?.call() ??
        AppDatabase.forTesting(
          // ignore: invalid_use_of_visible_for_testing_member
          inMemoryDatabase(),
        );
    getIt.registerSingleton<AppDatabase>(db);

    // DAOs — derived from the database singleton.
    // Mirrors `@Provides fun providePlantDao(db: AppDatabase) = db.plantDao()`
    getIt.registerSingleton<PlantDao>(getIt<AppDatabase>().plantDao);
    getIt.registerSingleton<GardenPlantingDao>(
      getIt<AppDatabase>().gardenPlantingDao,
    );

    // Network.
    // Mirrors `@Provides @Singleton fun provideRetrofit(okHttpClient: OkHttpClient)`
    getIt.registerSingleton<Dio>(dioFactory?.call() ?? createUnsplashDio());
    getIt.registerSingleton<UnsplashClient>(
      UnsplashClient(getIt<Dio>()),
    );
    getIt.registerSingleton<UnsplashService>(
      UnsplashService(getIt<UnsplashClient>()),
    );

    // Repositories.
    getIt.registerSingleton<PlantRepository>(
      PlantRepository(getIt<PlantDao>()),
    );
    getIt.registerSingleton<GardenPlantingRepository>(
      GardenPlantingRepository(getIt<GardenPlantingDao>()),
    );
    getIt.registerSingleton<UnsplashRepository>(
      UnsplashRepository(getIt<UnsplashClient>()),
    );

    await getIt.allReady();
  }

  // ---------------------------------------------------------------------------
  // Private registration helpers
  // ---------------------------------------------------------------------------

  /// Registers the [AppDatabase] and its DAOs.
  ///
  /// Mirrors Android's `DatabaseModule.kt`:
  /// ```kotlin
  /// @Provides @Singleton fun provideAppDatabase(context: Context): AppDatabase
  /// @Provides fun providePlantDao(db: AppDatabase): PlantDao = db.plantDao()
  /// @Provides fun provideGardenPlantingDao(db: AppDatabase): GardenPlantingDao
  /// ```
  static void _registerDatabase() {
    // AppDatabase — lazy singleton (created on first access).
    // Uses the on-disk SQLite database in production.
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
  /// Mirrors Android's `NetworkModule.kt`:
  /// ```kotlin
  /// @Provides @Singleton fun provideOkHttpClient(): OkHttpClient
  /// @Provides @Singleton fun provideRetrofit(client: OkHttpClient): Retrofit
  /// @Provides @Singleton fun provideUnsplashService(retrofit: Retrofit): UnsplashService
  /// ```
  static void _registerNetwork() {
    // Dio — lazy singleton with Unsplash configuration.
    // Mirrors the OkHttpClient + Retrofit setup in NetworkModule.kt.
    getIt.registerLazySingleton<Dio>(createUnsplashDio);

    // UnsplashClient — wraps the Dio instance.
    // Mirrors the Retrofit UnsplashService interface implementation.
    getIt.registerLazySingleton<UnsplashClient>(
      () => UnsplashClient(getIt<Dio>()),
    );

    // UnsplashService — service layer with logging.
    getIt.registerLazySingleton<UnsplashService>(
      () => UnsplashService(getIt<UnsplashClient>()),
    );
  }

  /// Registers the repository layer.
  ///
  /// Mirrors the `@Singleton` + `@Inject` constructor pattern used in
  /// Android repositories:
  /// ```kotlin
  /// @Singleton
  /// class PlantRepository @Inject constructor(private val plantDao: PlantDao)
  /// ```
  static void _registerRepositories() {
    // PlantRepository — wraps PlantDao.
    getIt.registerLazySingleton<PlantRepository>(
      () => PlantRepository(getIt<PlantDao>()),
    );

    // GardenPlantingRepository — wraps GardenPlantingDao.
    getIt.registerLazySingleton<GardenPlantingRepository>(
      () => GardenPlantingRepository(getIt<GardenPlantingDao>()),
    );

    // UnsplashRepository — wraps UnsplashClient for paginated search.
    getIt.registerLazySingleton<UnsplashRepository>(
      () => UnsplashRepository(getIt<UnsplashClient>()),
    );
  }
}
