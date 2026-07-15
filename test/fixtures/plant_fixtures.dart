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

/// Plant test fixtures.
///
/// Provides pre-built [PlantsCompanion] and [Plant]-like data for use in
/// unit and integration tests. Mirrors the `testPlants` list in the Android
/// `utilities/TestUtils.kt`.
library;

import 'package:drift/drift.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

// ---------------------------------------------------------------------------
// Plant companions (for database insertion)
// ---------------------------------------------------------------------------

/// A sunflower plant companion for database insertion.
final PlantsCompanion sunflowerCompanion = PlantsCompanion.insert(
  id: 'sunflower',
  name: 'Sunflower',
  description: 'A bright yellow flower that follows the sun.',
  growZoneNumber: 9,
  wateringInterval: const Value(7),
  imageUrl: const Value('https://example.com/sunflower.jpg'),
);

/// An apple tree plant companion for database insertion.
final PlantsCompanion appleCompanion = PlantsCompanion.insert(
  id: 'apple',
  name: 'Apple',
  description: 'A deciduous tree that produces apples.',
  growZoneNumber: 5,
  wateringInterval: const Value(3),
  imageUrl: const Value('https://example.com/apple.jpg'),
);

/// A beet plant companion for database insertion.
final PlantsCompanion beetCompanion = PlantsCompanion.insert(
  id: 'beet',
  name: 'Beet',
  description: 'A root vegetable with edible leaves.',
  growZoneNumber: 7,
  wateringInterval: const Value(5),
  imageUrl: const Value(''),
);

/// A tomato plant companion for database insertion.
///
/// Mirrors `Plant("1", "Tomato", "A red vegetable", 1, 2, "")` from
/// the Android `PlantTest`.
final PlantsCompanion tomatoCompanion = PlantsCompanion.insert(
  id: 'tomato',
  name: 'Tomato',
  description: 'A red vegetable.',
  growZoneNumber: 1,
  wateringInterval: const Value(2),
  imageUrl: const Value(''),
);

/// All plant companions as a list.
final List<PlantsCompanion> allPlantCompanions = [
  sunflowerCompanion,
  appleCompanion,
  beetCompanion,
  tomatoCompanion,
];

// ---------------------------------------------------------------------------
// Garden planting companions (for database insertion)
// ---------------------------------------------------------------------------

/// A reference date for test fixtures (September 4, 1998).
///
/// Mirrors `testCalendar` in the Android `TestUtils.kt`.
final DateTime testDate = DateTime(1998, 9, 4);

/// A garden planting companion for the sunflower plant.
GardenPlantingsCompanion sunflowerPlantingCompanion({
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: 'sunflower',
      plantDate: plantDate ?? testDate,
      lastWateringDate: lastWateringDate ?? testDate,
    );

/// A garden planting companion for the apple plant.
GardenPlantingsCompanion applePlantingCompanion({
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) =>
    newGardenPlanting(
      plantId: 'apple',
      plantDate: plantDate ?? testDate,
      lastWateringDate: lastWateringDate ?? testDate,
    );
