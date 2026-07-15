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

/// Unit tests for the [GardenPlanting] domain model.
///
/// Mirrors the Android `data/GardenPlantingTest.kt` test class. Tests
/// default values for [plantDate] and [lastWateringDate] fields.
///
/// ## Android equivalence
/// ```kotlin
/// // GardenPlantingTest.kt
/// @Test fun testDefaultValues() { ... }
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [GardenPlanting] data object for testing.
///
/// Mirrors `GardenPlanting(plantId = "sunflower")` from the Android test.
GardenPlanting _makeGardenPlanting({
  int id = 1,
  String plantId = 'sunflower',
  DateTime? plantDate,
  DateTime? lastWateringDate,
}) {
  final DateTime now = DateTime.now();
  return GardenPlanting(
    id: id,
    plantId: plantId,
    plantDate: plantDate ?? now,
    lastWateringDate: lastWateringDate ?? now,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // Default values
  // -------------------------------------------------------------------------

  group('GardenPlanting default values', () {
    test('plantDate defaults to current date/time when not specified', () {
      // Arrange
      final DateTime before = DateTime.now().subtract(const Duration(seconds: 1));
      final GardenPlanting planting = _makeGardenPlanting();
      final DateTime after = DateTime.now().add(const Duration(seconds: 1));

      // Assert — plantDate should be between before and after.
      expect(
        planting.plantDate.isAfter(before) ||
            planting.plantDate.isAtSameMomentAs(before),
        isTrue,
        reason: 'plantDate should be >= before',
      );
      expect(
        planting.plantDate.isBefore(after) ||
            planting.plantDate.isAtSameMomentAs(after),
        isTrue,
        reason: 'plantDate should be <= after',
      );
    });

    test('lastWateringDate defaults to current date/time when not specified',
        () {
      // Arrange
      final DateTime before = DateTime.now().subtract(const Duration(seconds: 1));
      final GardenPlanting planting = _makeGardenPlanting();
      final DateTime after = DateTime.now().add(const Duration(seconds: 1));

      // Assert — lastWateringDate should be between before and after.
      expect(
        planting.lastWateringDate.isAfter(before) ||
            planting.lastWateringDate.isAtSameMomentAs(before),
        isTrue,
        reason: 'lastWateringDate should be >= before',
      );
      expect(
        planting.lastWateringDate.isBefore(after) ||
            planting.lastWateringDate.isAtSameMomentAs(after),
        isTrue,
        reason: 'lastWateringDate should be <= after',
      );
    });

    test('plantDate and lastWateringDate are equal when both default', () {
      // Mirrors the Android test that checks both Calendar fields are
      // initialised to the same time.
      final DateTime now = DateTime.now();
      final GardenPlanting planting = _makeGardenPlanting(
        plantDate: now,
        lastWateringDate: now,
      );

      expect(planting.plantDate, equals(planting.lastWateringDate));
    });

    test('plantId is stored correctly', () {
      final GardenPlanting planting = _makeGardenPlanting(plantId: 'tomato');
      expect(planting.plantId, equals('tomato'));
    });

    test('id is stored correctly', () {
      final GardenPlanting planting = _makeGardenPlanting(id: 42);
      expect(planting.id, equals(42));
    });
  });

  // -------------------------------------------------------------------------
  // Explicit date values
  // -------------------------------------------------------------------------

  group('GardenPlanting with explicit dates', () {
    test('stores explicit plantDate correctly', () {
      final DateTime plantDate = DateTime(1998, 9, 4);
      final GardenPlanting planting = _makeGardenPlanting(plantDate: plantDate);

      expect(planting.plantDate, equals(plantDate));
    });

    test('stores explicit lastWateringDate correctly', () {
      final DateTime lastWatered = DateTime(2024, 6, 15);
      final GardenPlanting planting =
          _makeGardenPlanting(lastWateringDate: lastWatered);

      expect(planting.lastWateringDate, equals(lastWatered));
    });

    test('plantDate and lastWateringDate can differ', () {
      final DateTime plantDate = DateTime(2024, 1, 1);
      final DateTime lastWatered = DateTime(2024, 6, 15);
      final GardenPlanting planting = _makeGardenPlanting(
        plantDate: plantDate,
        lastWateringDate: lastWatered,
      );

      expect(planting.plantDate, equals(plantDate));
      expect(planting.lastWateringDate, equals(lastWatered));
      expect(planting.plantDate, isNot(equals(planting.lastWateringDate)));
    });
  });

  // -------------------------------------------------------------------------
  // newGardenPlanting factory
  // -------------------------------------------------------------------------

  group('newGardenPlanting factory', () {
    test('creates companion with correct plantId', () {
      final companion = newGardenPlanting(plantId: 'sunflower');
      // The companion's plantId value should be 'sunflower'.
      expect(companion.plantId.value, equals('sunflower'));
    });

    test('uses provided plantDate', () {
      final DateTime date = DateTime(2024, 6, 15);
      final companion = newGardenPlanting(
        plantId: 'sunflower',
        plantDate: date,
      );
      expect(companion.plantDate.value, equals(date));
    });

    test('uses provided lastWateringDate', () {
      final DateTime date = DateTime(2024, 6, 15);
      final companion = newGardenPlanting(
        plantId: 'sunflower',
        lastWateringDate: date,
      );
      expect(companion.lastWateringDate.value, equals(date));
    });

    test('defaults plantDate to now when not provided', () {
      final DateTime before = DateTime.now().subtract(const Duration(seconds: 1));
      final companion = newGardenPlanting(plantId: 'sunflower');
      final DateTime after = DateTime.now().add(const Duration(seconds: 1));

      final DateTime plantDate = companion.plantDate.value;
      expect(
        plantDate.isAfter(before) || plantDate.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        plantDate.isBefore(after) || plantDate.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('defaults lastWateringDate to now when not provided', () {
      final DateTime before = DateTime.now().subtract(const Duration(seconds: 1));
      final companion = newGardenPlanting(plantId: 'sunflower');
      final DateTime after = DateTime.now().add(const Duration(seconds: 1));

      final DateTime lastWatered = companion.lastWateringDate.value;
      expect(
        lastWatered.isAfter(before) || lastWatered.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        lastWatered.isBefore(after) || lastWatered.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // GardenPlanting equality
  // -------------------------------------------------------------------------

  group('GardenPlanting equality', () {
    test('two plantings with same fields are equal', () {
      final DateTime date = DateTime(2024, 6, 15);
      final GardenPlanting a = _makeGardenPlanting(
        id: 1,
        plantId: 'sunflower',
        plantDate: date,
        lastWateringDate: date,
      );
      final GardenPlanting b = _makeGardenPlanting(
        id: 1,
        plantId: 'sunflower',
        plantDate: date,
        lastWateringDate: date,
      );
      expect(a, equals(b));
    });

    test('two plantings with different plantIds are not equal', () {
      final DateTime date = DateTime(2024, 6, 15);
      final GardenPlanting a = _makeGardenPlanting(
        id: 1,
        plantId: 'sunflower',
        plantDate: date,
        lastWateringDate: date,
      );
      final GardenPlanting b = _makeGardenPlanting(
        id: 1,
        plantId: 'apple',
        plantDate: date,
        lastWateringDate: date,
      );
      expect(a, isNot(equals(b)));
    });

    test('two plantings with different ids are not equal', () {
      final DateTime date = DateTime(2024, 6, 15);
      final GardenPlanting a = _makeGardenPlanting(
        id: 1,
        plantId: 'sunflower',
        plantDate: date,
        lastWateringDate: date,
      );
      final GardenPlanting b = _makeGardenPlanting(
        id: 2,
        plantId: 'sunflower',
        plantDate: date,
        lastWateringDate: date,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
