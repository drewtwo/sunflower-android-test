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

/// Integration tests for plant watering status calculation.
///
/// Tests the watering status logic end-to-end using a real in-memory database.
/// Verifies that [PlantExtension.shouldBeWatered] works correctly with
/// actual [GardenPlanting] records from the database.
///
/// Mirrors the Android `PlantTest.kt` and `GardenPlantingDaoTest.kt` tests,
/// combining them into an integration-level test that exercises the full
/// data layer.
///
/// ## Running
/// ```sh
/// flutter test integration_test/plant_watering_test.dart
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';

// ---------------------------------------------------------------------------
// Test database setup
// ---------------------------------------------------------------------------

/// Creates an in-memory [AppDatabase] pre-seeded with plants of known
/// watering intervals.
Future<AppDatabase> _createWateringTestDatabase() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  await db.plantDao.insertPlants([
    // Sunflower: water every 7 days.
    PlantsCompanion.insert(
      id: 'sunflower',
      name: 'Sunflower',
      description: 'A bright yellow flower.',
      growZoneNumber: 9,
      wateringInterval: const Value(7),
      imageUrl: const Value(''),
    ),
    // Tomato: water every 2 days.
    PlantsCompanion.insert(
      id: 'tomato',
      name: 'Tomato',
      description: 'A red vegetable.',
      growZoneNumber: 1,
      wateringInterval: const Value(2),
      imageUrl: const Value(''),
    ),
    // Cactus: water every 30 days.
    PlantsCompanion.insert(
      id: 'cactus',
      name: 'Cactus',
      description: 'A drought-tolerant succulent.',
      growZoneNumber: 13,
      wateringInterval: const Value(30),
      imageUrl: const Value(''),
    ),
  ]);

  return db;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late PlantRepository plantRepository;
  late GardenPlantingRepository gardenRepository;

  setUp(() async {
    database = await _createWateringTestDatabase();
    plantRepository = PlantRepository(database.plantDao);
    gardenRepository = GardenPlantingRepository(database.gardenPlantingDao);
  });

  tearDown(() async {
    await database.close();
  });

  // -------------------------------------------------------------------------
  // shouldBeWatered — basic logic
  // Mirrors: PlantTest.kt testShouldBeWatered / testShouldNotBeWatered
  // -------------------------------------------------------------------------

  group('shouldBeWatered — basic logic', () {
    test('returns true when overdue for watering', () async {
      final plant = await plantRepository.getPlantById('sunflower');
      expect(plant, isNotNull);

      final DateTime now = DateTime(2024, 6, 15);
      // Last watered 10 days ago (interval is 7).
      final DateTime lastWatered = now.subtract(const Duration(days: 10));

      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isTrue,
      );
    });

    test('returns false when not yet due for watering', () async {
      final plant = await plantRepository.getPlantById('sunflower');
      expect(plant, isNotNull);

      final DateTime now = DateTime(2024, 6, 15);
      // Last watered 3 days ago (interval is 7).
      final DateTime lastWatered = now.subtract(const Duration(days: 3));

      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isFalse,
      );
    });

    test('returns false when watered exactly on the interval boundary', () async {
      final plant = await plantRepository.getPlantById('sunflower');
      expect(plant, isNotNull);

      final DateTime now = DateTime(2024, 6, 15);
      // Last watered exactly 7 days ago (interval is 7) — not yet overdue.
      final DateTime lastWatered = now.subtract(const Duration(days: 7));

      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isFalse,
      );
    });

    test('returns true when one day past the interval', () async {
      final plant = await plantRepository.getPlantById('sunflower');
      expect(plant, isNotNull);

      final DateTime now = DateTime(2024, 6, 15);
      // Last watered 8 days ago (interval is 7) — overdue by 1 day.
      final DateTime lastWatered = now.subtract(const Duration(days: 8));

      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // shouldBeWatered — different watering intervals
  // -------------------------------------------------------------------------

  group('shouldBeWatered — different intervals', () {
    test('tomato (2-day interval) needs watering after 3 days', () async {
      final plant = await plantRepository.getPlantById('tomato');
      expect(plant, isNotNull);
      expect(plant!.wateringInterval, equals(2));

      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 3));

      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isTrue,
      );
    });

    test('tomato (2-day interval) does not need watering after 1 day', () async {
      final plant = await plantRepository.getPlantById('tomato');
      expect(plant, isNotNull);

      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 1));

      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isFalse,
      );
    });

    test('cactus (30-day interval) does not need watering after 29 days',
        () async {
      final plant = await plantRepository.getPlantById('cactus');
      expect(plant, isNotNull);
      expect(plant!.wateringInterval, equals(30));

      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 29));

      expect(
        plant.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isFalse,
      );
    });

    test('cactus (30-day interval) needs watering after 31 days', () async {
      final plant = await plantRepository.getPlantById('cactus');
      expect(plant, isNotNull);

      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 31));

      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Watering status with database garden plantings
  // -------------------------------------------------------------------------

  group('Watering status with garden plantings', () {
    test('newly planted plant does not need watering', () async {
      final DateTime now = DateTime(2024, 6, 15);

      // Plant sunflower today.
      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: now,
        lastWateringDate: now,
      );

      final plant = await plantRepository.getPlantById('sunflower');
      final plantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;

      expect(plant, isNotNull);
      expect(plantings.length, equals(1));

      final lastWatered = plantings.first.lastWateringDate;
      expect(
        plant!.shouldBeWatered(since: now, lastWateringDate: lastWatered),
        isFalse,
      );
    });

    test('plant needs watering when last watered beyond interval', () async {
      final DateTime now = DateTime(2024, 6, 15);
      final DateTime lastWatered = now.subtract(const Duration(days: 10));

      // Plant sunflower with old last watering date.
      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: lastWatered,
        lastWateringDate: lastWatered,
      );

      final plant = await plantRepository.getPlantById('sunflower');
      final plantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;

      expect(plant, isNotNull);
      expect(plantings.length, equals(1));

      expect(
        plant!.shouldBeWatered(
          since: now,
          lastWateringDate: plantings.first.lastWateringDate,
        ),
        isTrue,
      );
    });

    test('watering status differs across plants with different intervals',
        () async {
      final DateTime now = DateTime(2024, 6, 15);
      // Last watered 5 days ago.
      final DateTime lastWatered = now.subtract(const Duration(days: 5));

      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower', // 7-day interval
        plantDate: lastWatered,
        lastWateringDate: lastWatered,
      );
      await gardenRepository.addPlantingWithDates(
        plantId: 'tomato', // 2-day interval
        plantDate: lastWatered,
        lastWateringDate: lastWatered,
      );

      final sunflower = await plantRepository.getPlantById('sunflower');
      final tomato = await plantRepository.getPlantById('tomato');

      final sunflowerPlantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;
      final tomatoPlantings =
          await gardenRepository.watchPlantingsForPlant('tomato').first;

      // Sunflower: 5 days < 7-day interval → does NOT need watering.
      expect(
        sunflower!.shouldBeWatered(
          since: now,
          lastWateringDate: sunflowerPlantings.first.lastWateringDate,
        ),
        isFalse,
      );

      // Tomato: 5 days > 2-day interval → DOES need watering.
      expect(
        tomato!.shouldBeWatered(
          since: now,
          lastWateringDate: tomatoPlantings.first.lastWateringDate,
        ),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Watering status with reference date (mirrors Android testCalendar)
  // -------------------------------------------------------------------------

  group('Watering status with reference date', () {
    /// Reference date mirrors `testCalendar` (September 4, 1998) from
    /// the Android `TestUtils.kt`.
    final DateTime testCalendar = DateTime(1998, 9, 4);

    test('plant planted on testCalendar does not need watering on same day',
        () async {
      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: testCalendar,
        lastWateringDate: testCalendar,
      );

      final plant = await plantRepository.getPlantById('sunflower');
      final plantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;

      expect(
        plant!.shouldBeWatered(
          since: testCalendar,
          lastWateringDate: plantings.first.lastWateringDate,
        ),
        isFalse,
      );
    });

    test('plant needs watering 8 days after testCalendar (7-day interval)',
        () async {
      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: testCalendar,
        lastWateringDate: testCalendar,
      );

      final plant = await plantRepository.getPlantById('sunflower');
      final plantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;

      final DateTime checkDate =
          testCalendar.add(const Duration(days: 8));

      expect(
        plant!.shouldBeWatered(
          since: checkDate,
          lastWateringDate: plantings.first.lastWateringDate,
        ),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Database persistence of watering dates
  // -------------------------------------------------------------------------

  group('Database persistence', () {
    test('lastWateringDate is stored and retrieved correctly', () async {
      final DateTime plantDate = DateTime(2024, 1, 1);
      final DateTime lastWatered = DateTime(2024, 6, 1);

      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: plantDate,
        lastWateringDate: lastWatered,
      );

      final plantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;

      expect(plantings.length, equals(1));
      expect(plantings.first.plantDate, equals(plantDate));
      expect(plantings.first.lastWateringDate, equals(lastWatered));
    });

    test('multiple plantings for same plant are stored correctly', () async {
      // Note: In practice the app prevents duplicate plantings, but the
      // database layer allows it for testing purposes.
      final DateTime date1 = DateTime(2024, 1, 1);
      final DateTime date2 = DateTime(2024, 6, 1);

      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: date1,
        lastWateringDate: date1,
      );
      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: date2,
        lastWateringDate: date2,
      );

      final plantings =
          await gardenRepository.watchPlantingsForPlant('sunflower').first;
      expect(plantings.length, equals(2));
    });
  });
}
