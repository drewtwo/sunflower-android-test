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

/// Unit tests for the [Plant] domain model and [PlantExtension].
///
/// Mirrors the Android `data/PlantTest.kt` test class. Tests the
/// [PlantExtension.shouldBeWatered] logic with various date scenarios.
///
/// ## Android equivalence
/// ```kotlin
/// // PlantTest.kt
/// @Test fun testShouldBeWatered() { ... }
/// @Test fun testShouldNotBeWatered() { ... }
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Plant] data object directly (bypassing drift's generated code)
/// for testing [PlantExtension] methods.
///
/// Mirrors `Plant("1", "Tomato", "A red vegetable", 1, 2, "")` from
/// the Android `PlantTest`.
Plant _makePlant({
  String id = 'tomato',
  String name = 'Tomato',
  String description = 'A red vegetable.',
  int growZoneNumber = 1,
  int wateringInterval = 2,
  String imageUrl = '',
}) =>
    Plant(
      id: id,
      name: name,
      description: description,
      growZoneNumber: growZoneNumber,
      wateringInterval: wateringInterval,
      imageUrl: imageUrl,
    );

void main() {
  group('PlantExtension.shouldBeWatered', () {
    // -----------------------------------------------------------------------
    // Mirrors Android PlantTest.testShouldBeWatered
    // -----------------------------------------------------------------------

    test('returns true when since is after lastWateringDate + wateringInterval',
        () {
      // Arrange — watering interval is 2 days.
      final Plant plant = _makePlant(wateringInterval: 2);

      // Last watered 3 days ago → should be watered (3 > 2).
      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 3));

      // Act
      final bool result = plant.shouldBeWatered(
        since: now,
        lastWateringDate: lastWatered,
      );

      // Assert
      expect(result, isTrue);
    });

    test('returns true when since is exactly one day past the interval', () {
      final Plant plant = _makePlant(wateringInterval: 7);

      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 8));

      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // Mirrors Android PlantTest.testShouldNotBeWatered
    // -----------------------------------------------------------------------

    test('returns false when since equals lastWateringDate + wateringInterval',
        () {
      // Arrange — watering interval is 2 days.
      final Plant plant = _makePlant(wateringInterval: 2);

      // Last watered exactly 2 days ago → NOT yet due (not strictly after).
      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 2));

      // Act
      final bool result = plant.shouldBeWatered(
        since: now,
        lastWateringDate: lastWatered,
      );

      // Assert
      expect(result, isFalse);
    });

    test('returns false when since is before lastWateringDate + wateringInterval',
        () {
      final Plant plant = _makePlant(wateringInterval: 7);

      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 3));

      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isFalse,
      );
    });

    test('returns false when watered today', () {
      final Plant plant = _makePlant(wateringInterval: 7);
      final DateTime now = DateTime(2024, 6, 15);

      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: now),
        isFalse,
      );
    });

    test('returns true for wateringInterval = 1 when watered yesterday', () {
      final Plant plant = _makePlant(wateringInterval: 1);
      final DateTime now = DateTime(2024, 6, 15);
      final DateTime yesterday = now.subtract(const Duration(days: 2));

      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: yesterday),
        isTrue,
      );
    });

    test('handles large wateringInterval correctly', () {
      final Plant plant = _makePlant(wateringInterval: 365);
      final DateTime now = DateTime(2024, 6, 15);

      // Watered 364 days ago — not yet due.
      final DateTime lastWatered364 = now.subtract(const Duration(days: 364));
      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: lastWatered364),
        isFalse,
      );

      // Watered 366 days ago — overdue.
      final DateTime lastWatered366 = now.subtract(const Duration(days: 366));
      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: lastWatered366),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // PlantExtension.toDisplayString
  // -------------------------------------------------------------------------

  group('PlantExtension.toDisplayString', () {
    test('returns the plant name', () {
      final Plant plant = _makePlant(name: 'Sunflower');
      expect(plant.toDisplayString(), equals('Sunflower'));
    });

    test('returns empty string when name is empty', () {
      final Plant plant = _makePlant(name: '');
      expect(plant.toDisplayString(), equals(''));
    });
  });

  // -------------------------------------------------------------------------
  // Plant equality (drift-generated data class)
  // -------------------------------------------------------------------------

  group('Plant equality', () {
    test('two plants with same fields are equal', () {
      final Plant a = _makePlant(id: 'tomato', name: 'Tomato');
      final Plant b = _makePlant(id: 'tomato', name: 'Tomato');
      expect(a, equals(b));
    });

    test('two plants with different ids are not equal', () {
      final Plant a = _makePlant(id: 'tomato');
      final Plant b = _makePlant(id: 'sunflower');
      expect(a, isNot(equals(b)));
    });
  });
}
