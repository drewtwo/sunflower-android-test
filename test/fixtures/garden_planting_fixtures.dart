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

/// Garden planting test fixtures.
///
/// Provides pre-built [GardenPlantingsCompanion] and [GardenPlanting]-like
/// data for use in unit and integration tests. Mirrors the
/// `testGardenPlanting` and `testCalendar` constants in the Android
/// `utilities/TestUtils.kt`.
library;

import 'package:drift/drift.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';

// ---------------------------------------------------------------------------
// Reference dates
// ---------------------------------------------------------------------------

/// A reference date for test fixtures: September 4, 1998.
///
/// Mirrors `testCalendar` in the Android `utilities/TestUtils.kt`:
/// ```kotlin
/// val testCalendar: Calendar = Calendar.getInstance().apply {
///   set(1998, Calendar.SEPTEMBER, 4)
/// }
/// ```
final DateTime testPlantDate = DateTime(1998, 9, 4);

/// A reference last-watering date for test fixtures: September 4, 1998.
final DateTime testLastWateringDate = DateTime(1998, 9, 4);

/// A "today" date for watering tests.
final DateTime today = DateTime(2024, 6, 15);

/// Yesterday's date for watering tests.
final DateTime yesterday = today.subtract(const Duration(days: 1));

/// Two days ago for watering tests.
final DateTime twoDaysAgo = today.subtract(const Duration(days: 2));

/// Three days ago for watering tests.
final DateTime threeDaysAgo = today.subtract(const Duration(days: 3));

// ---------------------------------------------------------------------------
// GardenPlantingsCompanion factories
// ---------------------------------------------------------------------------

/// Creates a [GardenPlantingsCompanion] for the sunflower plant.
///
/// Mirrors `testGardenPlanting` in the Android `TestUtils.kt`:
/// ```kotlin
/// val testGardenPlanting = GardenPlanting(testPlant.plantId, testCalendar, testCalendar)
/// ```
GardenPlantingsCompanion sunflowerGardenPlanting({
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: 'sunflower',
      plantDate: plantDate ?? testPlantDate,
      lastWateringDate: lastWateringDate ?? testLastWateringDate,
    );

/// Creates a [GardenPlantingsCompanion] for the apple plant.
GardenPlantingsCompanion appleGardenPlanting({
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: 'apple',
      plantDate: plantDate ?? testPlantDate,
      lastWateringDate: lastWateringDate ?? testLastWateringDate,
    );

/// Creates a [GardenPlantingsCompanion] for the beet plant.
GardenPlantingsCompanion beetGardenPlanting({
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: 'beet',
      plantDate: plantDate ?? testPlantDate,
      lastWateringDate: lastWateringDate ?? testLastWateringDate,
    );

/// Creates a [GardenPlantingsCompanion] for the tomato plant.
GardenPlantingsCompanion tomatoGardenPlanting({
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: 'tomato',
      plantDate: plantDate ?? testPlantDate,
      lastWateringDate: lastWateringDate ?? testLastWateringDate,
    );

/// Creates a [GardenPlantingsCompanion] for any plant by [plantId].
GardenPlantingsCompanion gardenPlantingFor(
  String plantId, {
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: plantId,
      plantDate: plantDate ?? testPlantDate,
      lastWateringDate: lastWateringDate ?? testLastWateringDate,
    );

// ---------------------------------------------------------------------------
// GardenPlanting data objects (for assertion)
// ---------------------------------------------------------------------------

/// Creates a [GardenPlanting] data object for assertions in tests.
///
/// Note: [id] defaults to 0 since auto-increment IDs are assigned by the DB.
GardenPlanting makeGardenPlanting({
  int id = 0,
  required String plantId,
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    GardenPlanting(
      id: id,
      plantId: plantId,
      plantDate: plantDate ?? testPlantDate,
      lastWateringDate: lastWateringDate ?? testLastWateringDate,
    );

// ---------------------------------------------------------------------------
// Watering scenario helpers
// ---------------------------------------------------------------------------

/// Returns a [GardenPlantingsCompanion] where the plant was last watered
/// [daysAgo] days before [referenceDate].
GardenPlantingsCompanion plantingLastWateredDaysAgo(
  String plantId,
  int daysAgo, {
  DateTime? referenceDate,
}) {
  final DateTime ref = referenceDate ?? today;
  final DateTime lastWatered = ref.subtract(Duration(days: daysAgo));
  return newGardenPlanting(
    plantId: plantId,
    plantDate: testPlantDate,
    lastWateringDate: lastWatered,
  );
}

// ---------------------------------------------------------------------------
// Companion with explicit Value fields (for testing default handling)
// ---------------------------------------------------------------------------

/// A [GardenPlantingsCompanion] with all fields explicitly set.
final GardenPlantingsCompanion explicitSunflowerPlanting =
    GardenPlantingsCompanion.insert(
  plantId: 'sunflower',
  plantDate: Value(testPlantDate),
  lastWateringDate: Value(testLastWateringDate),
);
