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

/// Drift table definition and data class for a garden planting.
///
/// Mirrors the Android Room `@Entity(tableName = "garden_plantings")` class
/// defined in `data/GardenPlanting.kt`.
///
/// A [GardenPlanting] represents when a user adds a [Plant] to their garden,
/// with useful metadata such as [plantDate] and [lastWateringDate].
///
/// ## Android → Dart mapping
/// | Android (Room)                    | Dart (drift)                        |
/// |-----------------------------------|-------------------------------------|
/// | `@Entity(tableName = ...)`        | `class GardenPlantings extends Table` |
/// | `@ForeignKey(entity = Plant::class)` | `.references(Plants, #id, ...)`  |
/// | `@Index("plant_id")`              | drift handles indexing automatically |
/// | `Calendar` fields                 | `DateTimeColumn` (stored as Unix ms) |
/// | `@PrimaryKey(autoGenerate = true)`| `integer().autoIncrement()()`       |
library;

import 'package:drift/drift.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

// ---------------------------------------------------------------------------
// Table definition
// ---------------------------------------------------------------------------

/// Drift table definition for the `garden_plantings` table.
///
/// Mirrors the Android Room `GardenPlanting` entity:
/// - `id`                 → auto-increment primary key (mirrors `gardenPlantingId`)
/// - `plant_id`           → foreign key → `plants.id`
/// - `plant_date`         → when the plant was added to the garden
/// - `last_watering_date` → when the plant was last watered
///
/// Drift stores [DateTime] columns as Unix timestamps (milliseconds since
/// epoch) in the SQLite database, replacing the Android `Calendar` type
/// and the `Converters.kt` type converter.
class GardenPlantings extends Table {
  /// Auto-generated primary key.
  ///
  /// Mirrors `@PrimaryKey(autoGenerate = true) var gardenPlantingId: Long = 0`.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key referencing [Plants.id].
  ///
  /// Mirrors `@ColumnInfo(name = "plant_id") val plantId: String` with the
  /// `@ForeignKey` annotation pointing to `Plant::class`.
  ///
  /// `onDelete: KeyAction.cascade` ensures that deleting a plant also removes
  /// all its garden plantings — equivalent to Android's `ForeignKey.CASCADE`.
  TextColumn get plantId =>
      text().references(Plants, #id, onDelete: KeyAction.cascade)();

  /// The date the plant was added to the garden.
  ///
  /// Mirrors `@ColumnInfo(name = "plant_date") val plantDate: Calendar`.
  /// Stored as a Unix timestamp (milliseconds since epoch) via drift's
  /// built-in [DateTime] column type. Defaults to the current date/time.
  DateTimeColumn get plantDate => dateTime().withDefault(
        currentDateAndTime,
      )();

  /// The date the plant was last watered.
  ///
  /// Mirrors `@ColumnInfo(name = "last_watering_date") val lastWateringDate: Calendar`.
  /// Defaults to the current date/time (same as [plantDate]).
  DateTimeColumn get lastWateringDate => dateTime().withDefault(
        currentDateAndTime,
      )();
}

// ---------------------------------------------------------------------------
// Companion / helper
// ---------------------------------------------------------------------------

/// A convenience factory for creating a [GardenPlantingsCompanion] with
/// sensible defaults (both dates default to [DateTime.now]).
///
/// Mirrors the Android `GardenPlanting(plantId)` constructor call in
/// `GardenPlantingRepository.createGardenPlanting()`.
///
/// Example:
/// ```dart
/// final companion = newGardenPlanting(plantId: 'sunflower');
/// await db.gardenPlantingDao.insertGardenPlanting(companion);
/// ```
GardenPlantingsCompanion newGardenPlanting({
  required String plantId,
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) {
  final DateTime now = DateTime.now();
  return GardenPlantingsCompanion.insert(
    plantId: plantId,
    plantDate: Value(plantDate ?? now),
    lastWateringDate: Value(lastWateringDate ?? now),
  );
}
