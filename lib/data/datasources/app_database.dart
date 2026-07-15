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

/// Drift database definition for the Sunflower app.
///
/// Mirrors the Android Room `AppDatabase` class defined in
/// `data/AppDatabase.kt`. Defines the database, tables, DAOs, and the
/// pre-population callback that seeds plant data from `assets/plants.json`.
///
/// ## Code generation
/// Run `flutter pub run build_runner build --delete-conflicting-outputs`
/// to generate `app_database.g.dart`.
///
/// ## Migration strategy
/// - Version 1: initial schema (plants + garden_plantings tables).
/// - Future migrations should be added to [AppDatabase.migration] using
///   drift's `MigrationStrategy` with explicit `from`/`to` steps.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Plant DAO
// ---------------------------------------------------------------------------

/// Data access object for the [Plants] table.
///
/// Mirrors the Android Room `PlantDao` interface defined in `data/PlantDao.kt`.
@DriftAccessor(tables: [Plants])
class PlantDao extends DatabaseAccessor<AppDatabase> with _$PlantDaoMixin {
  /// Creates a [PlantDao] bound to [db].
  PlantDao(super.db);

  /// Returns a stream of all plants, ordered alphabetically by name.
  Stream<List<Plant>> watchAllPlants() =>
      (select(plants)..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();

  /// Returns a stream of plants filtered to the given [growZoneNumber].
  Stream<List<Plant>> watchPlantsWithGrowZone(int growZoneNumber) => (select(
        plants,
      )..where((p) => p.growZoneNumber.equals(growZoneNumber))
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  /// Returns the plant with the given [plantId], or `null` if not found.
  Future<Plant?> getPlantById(String plantId) =>
      (select(plants)..where((p) => p.id.equals(plantId))).getSingleOrNull();

  /// Inserts or replaces all [plantList] entries in the database.
  Future<void> insertPlants(List<PlantsCompanion> plantList) =>
      batch((b) => b.insertAllOnConflictUpdate(plants, plantList));
}

// ---------------------------------------------------------------------------
// Garden Planting DAO
// ---------------------------------------------------------------------------

/// Data access object for the [GardenPlantings] table.
///
/// Mirrors the Android Room `GardenPlantingDao` interface defined in
/// `data/GardenPlantingDao.kt`.
@DriftAccessor(tables: [GardenPlantings, Plants])
class GardenPlantingDao extends DatabaseAccessor<AppDatabase>
    with _$GardenPlantingDaoMixin {
  /// Creates a [GardenPlantingDao] bound to [db].
  GardenPlantingDao(super.db);

  /// Returns a stream of all garden plantings, joined with their plant data.
  Stream<List<GardenPlantingWithPlant>> watchGardenPlantingsWithPlants() {
    final query = select(gardenPlantings).join([
      innerJoin(plants, plants.id.equalsExp(gardenPlantings.plantId)),
    ]);
    return query
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => GardenPlantingWithPlant(
                  gardenPlanting: row.readTable(gardenPlantings),
                  plant: row.readTable(plants),
                ),
              )
              .toList(),
        );
  }

  /// Returns a stream of all garden plantings for the given [plantId].
  Stream<List<GardenPlanting>> watchGardenPlantingsForPlant(String plantId) =>
      (select(gardenPlantings)
            ..where((gp) => gp.plantId.equals(plantId)))
          .watch();

  /// Returns `true` if the plant with [plantId] is already in the garden.
  Future<bool> isPlanted(String plantId) async {
    final count = await (select(gardenPlantings)
          ..where((gp) => gp.plantId.equals(plantId)))
        .get();
    return count.isNotEmpty;
  }

  /// Inserts a new [companion] into the garden_plantings table.
  Future<int> insertGardenPlanting(GardenPlantingsCompanion companion) =>
      into(gardenPlantings).insert(companion);

  /// Deletes the garden planting with the given [plantId].
  Future<int> deleteGardenPlanting(String plantId) =>
      (delete(gardenPlantings)
            ..where((gp) => gp.plantId.equals(plantId)))
          .go();
}

// ---------------------------------------------------------------------------
// Join result
// ---------------------------------------------------------------------------

/// Holds a [GardenPlanting] together with its associated [Plant].
///
/// Mirrors the Android `PlantAndGardenPlantings` data class.
class GardenPlantingWithPlant {
  /// Creates a [GardenPlantingWithPlant] instance.
  const GardenPlantingWithPlant({
    required this.gardenPlanting,
    required this.plant,
  });

  /// The garden planting record.
  final GardenPlanting gardenPlanting;

  /// The plant associated with this garden planting.
  final Plant plant;
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

/// The drift database for the Sunflower app.
///
/// Mirrors the Android Room `AppDatabase` class. Contains two tables:
/// [Plants] and [GardenPlantings].
///
/// On first creation the database is pre-populated with plant data from
/// `assets/plants.json` (mirrors the Android `SeedDatabaseWorker`).
@DriftDatabase(
  tables: [Plants, GardenPlantings],
  daos: [PlantDao, GardenPlantingDao],
)
class AppDatabase extends _$AppDatabase {
  /// Creates an [AppDatabase] using the default on-disk location.
  AppDatabase() : super(_openConnection());

  /// Creates an [AppDatabase] backed by an in-memory database.
  ///
  /// Used in tests to avoid touching the file system.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDatabase();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here.
          // Example:
          //   if (from < 2) { await m.addColumn(plants, plants.someNewColumn); }
        },
      );

  /// Seeds the database with plant data from `assets/plants.json`.
  ///
  /// Mirrors the Android `SeedDatabaseWorker`.
  Future<void> _seedDatabase() async {
    final String jsonString =
        await rootBundle.loadString(plantDataFilename);
    final List<dynamic> jsonList =
        json.decode(jsonString) as List<dynamic>;

    final List<PlantsCompanion> companions = jsonList
        .cast<Map<String, dynamic>>()
        .map(
          (map) => PlantsCompanion.insert(
            id: map['plantId'] as String,
            name: map['name'] as String,
            description: map['description'] as String,
            growZoneNumber: map['growZoneNumber'] as int,
            wateringInterval: Value(
              (map['wateringInterval'] as int?) ?? 7,
            ),
            imageUrl: Value((map['imageUrl'] as String?) ?? ''),
          ),
        )
        .toList();

    await plantDao.insertPlants(companions);
  }
}

// ---------------------------------------------------------------------------
// Connection factory
// ---------------------------------------------------------------------------

/// Opens the SQLite connection for the on-disk [AppDatabase].
LazyDatabase _openConnection() => LazyDatabase(() async {
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dbFolder.path, databaseName));
      return NativeDatabase.createInBackground(file);
    });
