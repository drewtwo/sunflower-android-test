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

/// Repository for garden planting data.
///
/// Mirrors the Android `data/GardenPlantingRepository.kt` class. Acts as a
/// single source of truth for garden planting data, abstracting the
/// underlying [GardenPlantingDao] from the rest of the application.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@Singleton` + `@Inject`          | `get_it` singleton registration     |
/// | `suspend fun createGardenPlanting`| `Future<void> addPlanting(...)`     |
/// | `suspend fun removeGardenPlanting`| `Future<void> removePlanting(...)`  |
/// | `fun isPlanted(plantId)`          | `watchIsPlanted(plantId)`           |
/// | `fun getPlantedGardens()`         | `watchGardenPlantings()`            |
///
/// ## Usage
/// ```dart
/// final repo = getIt<GardenPlantingRepository>();
/// await repo.addPlanting('sunflower');
/// repo.watchGardenPlantings().listen((plantings) => print(plantings.length));
/// ```
library;

import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';

/// Repository module for handling garden planting data operations.
///
/// This class is registered as a singleton in [ServiceLocator] and should
/// be accessed via `getIt<GardenPlantingRepository>()`.
class GardenPlantingRepository {
  /// Creates a [GardenPlantingRepository] with the given [_gardenPlantingDao].
  const GardenPlantingRepository(this._gardenPlantingDao);

  final GardenPlantingDao _gardenPlantingDao;

  /// Adds a new planting for the plant with [plantId] to the garden.
  ///
  /// Mirrors `suspend fun createGardenPlanting(plantId: String)` which
  /// creates a new [GardenPlanting] with default dates and inserts it.
  ///
  /// Throws if the plant with [plantId] does not exist (foreign key constraint).
  Future<void> addPlanting(String plantId) async {
    final companion = newGardenPlanting(plantId: plantId);
    await _gardenPlantingDao.insertGardenPlanting(companion);
  }

  /// Adds a new planting with explicit [plantDate] and [lastWateringDate].
  ///
  /// Useful for testing or restoring data from a backup.
  Future<void> addPlantingWithDates({
    required String plantId,
    required DateTime plantDate,
    required DateTime lastWateringDate,
  }) async {
    final companion = newGardenPlanting(
      plantId: plantId,
      plantDate: plantDate,
      lastWateringDate: lastWateringDate,
    );
    await _gardenPlantingDao.insertGardenPlanting(companion);
  }

  /// Removes the garden planting for the plant with [plantId].
  ///
  /// Mirrors `suspend fun removeGardenPlanting(gardenPlanting: GardenPlanting)`
  /// which calls `gardenPlantingDao.deleteGardenPlanting(gardenPlanting)`.
  ///
  /// Returns the number of rows deleted (0 if no planting existed).
  Future<int> removePlanting(String plantId) =>
      _gardenPlantingDao.deleteGardenPlanting(plantId);

  /// Removes the garden planting with the given [id].
  Future<int> removePlantingById(int id) =>
      _gardenPlantingDao.deleteGardenPlantingById(id);

  /// Returns a stream that emits `true` if the plant with [plantId] is planted.
  ///
  /// Mirrors `fun isPlanted(plantId: String) = gardenPlantingDao.isPlanted(plantId)`.
  Stream<bool> watchIsPlanted(String plantId) =>
      _gardenPlantingDao.watchIsPlanted(plantId);

  /// Returns a future that resolves to `true` if the plant with [plantId]
  /// is already in the garden.
  Future<bool> isPlanted(String plantId) =>
      _gardenPlantingDao.isPlanted(plantId);

  /// Returns a stream of all garden plantings joined with their plant data.
  ///
  /// Mirrors `fun getPlantedGardens() = gardenPlantingDao.getPlantedGardens()`.
  /// The stream automatically emits a new list whenever the garden_plantings
  /// table changes.
  Stream<List<GardenPlantingWithPlant>> watchGardenPlantings() =>
      _gardenPlantingDao.watchGardenPlantingsWithPlants();

  /// Returns a stream of garden plantings for the plant with [plantId].
  Stream<List<GardenPlanting>> watchPlantingsForPlant(String plantId) =>
      _gardenPlantingDao.watchGardenPlantingsForPlant(plantId);
}
