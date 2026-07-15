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
library;

import 'package:drift/drift.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

// ---------------------------------------------------------------------------
// Table definition
// ---------------------------------------------------------------------------

/// Drift table definition for the `garden_plantings` table.
///
/// Mirrors the Android Room `GardenPlanting` entity:
/// - `id`                 → auto-increment primary key
/// - `plant_id`           → foreign key → `plants.id`
/// - `plant_date`         → when the plant was added to the garden
/// - `last_watering_date` → when the plant was last watered
class GardenPlantings extends Table {
  /// Auto-generated primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key referencing [Plants.id].
  TextColumn get plantId =>
      text().references(Plants, #id, onDelete: KeyAction.cascade)();

  /// The date the plant was added to the garden.
  ///
  /// Stored as a Unix timestamp (milliseconds since epoch) via drift's
  /// built-in [DateTime] column type.
  DateTimeColumn get plantDate => dateTime().withDefault(
        currentDateAndTime,
      )();

  /// The date the plant was last watered.
  DateTimeColumn get lastWateringDate => dateTime().withDefault(
        currentDateAndTime,
      )();
}

// ---------------------------------------------------------------------------
// Companion / helper
// ---------------------------------------------------------------------------

/// A convenience factory for creating a [GardenPlantingsCompanion] with
/// sensible defaults (both dates default to [DateTime.now]).
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
