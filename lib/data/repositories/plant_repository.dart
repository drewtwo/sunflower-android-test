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

/// Repository for plant data.
///
/// Mirrors the Android `data/PlantRepository.kt` class. Acts as a single
/// source of truth for plant data, abstracting the underlying [PlantDao]
/// from the rest of the application.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@Singleton` + `@Inject`          | `get_it` singleton registration     |
/// | `Flow<List<Plant>>`               | `Stream<List<Plant>>`               |
/// | `fun getPlants()`                 | `watchAllPlants()`                  |
/// | `fun getPlant(plantId)`           | `watchPlantById(plantId)`           |
/// | `fun getPlantsWithGrowZoneNumber` | `watchPlantsWithGrowZone(zone)`     |
///
/// ## Usage
/// ```dart
/// final repo = getIt<PlantRepository>();
/// repo.watchAllPlants().listen((plants) => print(plants.length));
/// ```
library;

import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

/// Repository module for handling plant data operations.
///
/// Collecting from the [Stream]s in [PlantDao] is main-safe. Drift moves
/// query execution off of the main thread automatically, mirroring Room's
/// coroutine support.
///
/// This class is registered as a singleton in [ServiceLocator] and should
/// be accessed via `getIt<PlantRepository>()`.
class PlantRepository {
  /// Creates a [PlantRepository] with the given [_plantDao].
  ///
  /// In production, this is called by [ServiceLocator] with the DAO
  /// obtained from the [AppDatabase] singleton.
  const PlantRepository(this._plantDao);

  final PlantDao _plantDao;

  /// Returns a stream of all plants, ordered alphabetically by name.
  ///
  /// Mirrors `fun getPlants() = plantDao.getPlants()`.
  /// The stream automatically emits a new list whenever the plants table
  /// changes (insert, update, or delete).
  Stream<List<Plant>> watchAllPlants() => _plantDao.watchAllPlants();

  /// Returns a stream of the plant with the given [plantId].
  ///
  /// Emits `null` if no plant with [plantId] exists.
  /// Mirrors `fun getPlant(plantId: String) = plantDao.getPlant(plantId)`.
  Stream<Plant?> watchPlantById(String plantId) =>
      _plantDao.watchPlantById(plantId);

  /// Returns a future that resolves to the plant with [plantId], or `null`.
  ///
  /// Use this for one-shot reads; prefer [watchPlantById] for reactive UIs.
  Future<Plant?> getPlantById(String plantId) =>
      _plantDao.getPlantById(plantId);

  /// Returns a stream of plants filtered to the given [growZoneNumber].
  ///
  /// Mirrors `fun getPlantsWithGrowZoneNumber(growZoneNumber: Int)
  ///   = plantDao.getPlantsWithGrowZoneNumber(growZoneNumber)`.
  Stream<List<Plant>> watchPlantsWithGrowZone(int growZoneNumber) =>
      _plantDao.watchPlantsWithGrowZone(growZoneNumber);
}
