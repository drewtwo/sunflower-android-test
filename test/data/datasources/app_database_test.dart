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

/// Database layer tests using drift in-memory database.
///
/// Ports the Android instrumented tests:
/// - `data/PlantDaoTest.kt`          → [PlantDao] tests
/// - `data/GardenPlantingDaoTest.kt` → [GardenPlantingDao] tests
///
/// Uses [AppDatabase.forTesting] with an in-memory SQLite database to avoid
/// touching the file system, mirroring Android's
/// `Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java).build()`.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@Before fun createDb()`          | `setUp(() async { ... })`           |
/// | `@After fun closeDb()`            | `tearDown(() async { ... })`        |
/// | `runBlocking { ... }`             | `() async { ... }`                  |
/// | `flow.first()`                    | `stream.first`                      |
/// | `assertThat(x, equalTo(y))`       | `expect(x, equals(y))`              |
/// | `assertTrue(x)` / `assertFalse`   | `expect(x, isTrue)` / `isFalse`    |
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';

import '../../fixtures/plant_fixtures.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates an in-memory [AppDatabase] for testing.
///
/// Mirrors `Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java).build()`.
AppDatabase _createTestDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  // ===========================================================================
  // PlantDao tests
  // Mirrors: app/src/androidTest/.../data/PlantDaoTest.kt
  // ===========================================================================

  group('PlantDao', () {
    late AppDatabase database;
    late PlantDao plantDao;

    // Plants matching the Android test fixtures:
    // plantA = Plant("1", "A", "", 1, 1, "")
    // plantB = Plant("2", "B", "", 1, 1, "")
    // plantC = Plant("3", "C", "", 2, 2, "")
    final plantA = PlantsCompanion.insert(
      id: '1',
      name: 'A',
      description: '',
      growZoneNumber: 1,
    );
    final plantB = PlantsCompanion.insert(
      id: '2',
      name: 'B',
      description: '',
      growZoneNumber: 1,
    );
    final plantC = PlantsCompanion.insert(
      id: '3',
      name: 'C',
      description: '',
      growZoneNumber: 2,
    );

    setUp(() async {
      database = _createTestDatabase();
      plantDao = database.plantDao;

      // Insert plants in non-alphabetical order to test that results are
      // sorted by name. Mirrors the Android setUp:
      // `plantDao.upsertAll(listOf(plantB, plantC, plantA))`
      await plantDao.insertPlants([plantB, plantC, plantA]);
    });

    tearDown(() async {
      await database.close();
    });

    // -------------------------------------------------------------------------
    // testGetPlants
    // Mirrors: @Test fun testGetPlants()
    // -------------------------------------------------------------------------

    group('watchAllPlants', () {
      test('returns all plants sorted alphabetically by name', () async {
        // Act — mirrors `plantDao.getPlants().first()`
        final List<Plant> plantList = await plantDao.watchAllPlants().first;

        // Assert — mirrors `assertThat(plantList.size, equalTo(3))`
        expect(plantList.length, equals(3));

        // Ensure plant list is sorted by name (A, B, C).
        // Mirrors:
        // assertThat(plantList[0], equalTo(plantA))
        // assertThat(plantList[1], equalTo(plantB))
        // assertThat(plantList[2], equalTo(plantC))
        expect(plantList[0].id, equals('1')); // plantA
        expect(plantList[0].name, equals('A'));
        expect(plantList[1].id, equals('2')); // plantB
        expect(plantList[1].name, equals('B'));
        expect(plantList[2].id, equals('3')); // plantC
        expect(plantList[2].name, equals('C'));
      });

      test('emits updated list when a plant is inserted', () async {
        // Arrange — listen to the stream before inserting.
        final stream = plantDao.watchAllPlants();

        // Act — insert a new plant.
        await plantDao.insertPlants([
          PlantsCompanion.insert(
            id: '4',
            name: 'D',
            description: '',
            growZoneNumber: 3,
          ),
        ]);

        // Assert — the stream should eventually emit 4 plants.
        final List<Plant> updated = await stream.first;
        expect(updated.length, equals(4));
      });
    });

    // -------------------------------------------------------------------------
    // testGetPlantsWithGrowZoneNumber
    // Mirrors: @Test fun testGetPlantsWithGrowZoneNumber()
    // -------------------------------------------------------------------------

    group('watchPlantsWithGrowZone', () {
      test('returns plants filtered by grow zone number', () async {
        // Mirrors:
        // val plantList = plantDao.getPlantsWithGrowZoneNumber(1).first()
        // assertThat(plantList.size, equalTo(2))
        final List<Plant> zone1Plants =
            await plantDao.watchPlantsWithGrowZone(1).first;
        expect(zone1Plants.length, equals(2));

        // Mirrors: assertThat(plantDao.getPlantsWithGrowZoneNumber(2).first().size, equalTo(1))
        final List<Plant> zone2Plants =
            await plantDao.watchPlantsWithGrowZone(2).first;
        expect(zone2Plants.length, equals(1));

        // Mirrors: assertThat(plantDao.getPlantsWithGrowZoneNumber(3).first().size, equalTo(0))
        final List<Plant> zone3Plants =
            await plantDao.watchPlantsWithGrowZone(3).first;
        expect(zone3Plants.length, equals(0));
      });

      test('returns zone-filtered plants sorted alphabetically', () async {
        // Mirrors:
        // assertThat(plantList[0], equalTo(plantA))
        // assertThat(plantList[1], equalTo(plantB))
        final List<Plant> zone1Plants =
            await plantDao.watchPlantsWithGrowZone(1).first;
        expect(zone1Plants[0].id, equals('1')); // plantA
        expect(zone1Plants[0].name, equals('A'));
        expect(zone1Plants[1].id, equals('2')); // plantB
        expect(zone1Plants[1].name, equals('B'));
      });

      test('returns empty list for non-existent grow zone', () async {
        final List<Plant> plants =
            await plantDao.watchPlantsWithGrowZone(99).first;
        expect(plants, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // testGetPlant
    // Mirrors: @Test fun testGetPlant()
    // -------------------------------------------------------------------------

    group('getPlantById', () {
      test('returns plant by id', () async {
        // Mirrors: `assertThat(plantDao.getPlant(plantA.plantId).first(), equalTo(plantA))`
        final Plant? plant = await plantDao.getPlantById('1');

        expect(plant, isNotNull);
        expect(plant!.id, equals('1'));
        expect(plant.name, equals('A'));
        expect(plant.growZoneNumber, equals(1));
      });

      test('returns null for non-existent plant id', () async {
        final Plant? plant = await plantDao.getPlantById('non-existent');
        expect(plant, isNull);
      });
    });

    group('watchPlantById', () {
      test('emits plant when found', () async {
        final Plant? plant = await plantDao.watchPlantById('1').first;

        expect(plant, isNotNull);
        expect(plant!.id, equals('1'));
        expect(plant.name, equals('A'));
      });

      test('emits null when plant not found', () async {
        final Plant? plant =
            await plantDao.watchPlantById('non-existent').first;
        expect(plant, isNull);
      });
    });
  });

  // ===========================================================================
  // GardenPlantingDao tests
  // Mirrors: app/src/androidTest/.../data/GardenPlantingDaoTest.kt
  // ===========================================================================

  group('GardenPlantingDao', () {
    late AppDatabase database;
    late GardenPlantingDao gardenPlantingDao;
    late int testGardenPlantingId;

    // Reference date mirrors `testCalendar` (September 4, 1998).
    final DateTime testCalendar = DateTime(1998, 9, 4);

    setUp(() async {
      database = _createTestDatabase();
      gardenPlantingDao = database.gardenPlantingDao;

      // Insert test plants — mirrors `database.plantDao().upsertAll(testPlants)`
      await database.plantDao.insertPlants(allPlantCompanions);

      // Insert the first garden planting — mirrors:
      // `testGardenPlantingId = gardenPlantingDao.insertGardenPlanting(testGardenPlanting)`
      testGardenPlantingId = await gardenPlantingDao.insertGardenPlanting(
        newGardenPlanting(
          plantId: 'sunflower', // testPlant = testPlants[0]
          plantDate: testCalendar,
          lastWateringDate: testCalendar,
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    // -------------------------------------------------------------------------
    // testGetGardenPlantings
    // Mirrors: @Test fun testGetGardenPlantings()
    // -------------------------------------------------------------------------

    group('watchGardenPlantingsWithPlants', () {
      test('returns all garden plantings with plant data', () async {
        // Insert a second planting — mirrors:
        // `val gardenPlanting2 = GardenPlanting(testPlants[1].plantId, ...)`
        await gardenPlantingDao.insertGardenPlanting(
          newGardenPlanting(
            plantId: 'apple', // testPlants[1]
            plantDate: testCalendar,
            lastWateringDate: testCalendar,
          ),
        );

        // Mirrors: `assertThat(gardenPlantingDao.getGardenPlantings().first().size, equalTo(2))`
        final plantings =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;
        expect(plantings.length, equals(2));
      });

      test('returns single planting after setUp', () async {
        final plantings =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;
        expect(plantings.length, equals(1));
      });
    });

    // -------------------------------------------------------------------------
    // testDeleteGardenPlanting
    // Mirrors: @Test fun testDeleteGardenPlanting()
    // -------------------------------------------------------------------------

    group('deleteGardenPlanting', () {
      test('removes planting and reduces count', () async {
        // Insert a second planting.
        await gardenPlantingDao.insertGardenPlanting(
          newGardenPlanting(
            plantId: 'apple',
            plantDate: testCalendar,
            lastWateringDate: testCalendar,
          ),
        );

        // Verify we have 2 plantings.
        // Mirrors: `assertThat(gardenPlantingDao.getGardenPlantings().first().size, equalTo(2))`
        final before =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;
        expect(before.length, equals(2));

        // Delete the apple planting.
        // Mirrors: `gardenPlantingDao.deleteGardenPlanting(gardenPlanting2)`
        await gardenPlantingDao.deleteGardenPlanting('apple');

        // Verify we're back to 1.
        // Mirrors: `assertThat(gardenPlantingDao.getGardenPlantings().first().size, equalTo(1))`
        final after =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;
        expect(after.length, equals(1));
      });

      test('returns number of rows deleted', () async {
        final int deleted =
            await gardenPlantingDao.deleteGardenPlanting('sunflower');
        expect(deleted, equals(1));
      });

      test('returns 0 when planting does not exist', () async {
        final int deleted =
            await gardenPlantingDao.deleteGardenPlanting('non-existent');
        expect(deleted, equals(0));
      });
    });

    // -------------------------------------------------------------------------
    // testGetGardenPlantingForPlant (isPlanted = true)
    // Mirrors: @Test fun testGetGardenPlantingForPlant()
    // -------------------------------------------------------------------------

    group('isPlanted', () {
      test('returns true when plant is in the garden', () async {
        // Mirrors: `assertTrue(gardenPlantingDao.isPlanted(testPlant.plantId).first())`
        final bool planted = await gardenPlantingDao.isPlanted('sunflower');
        expect(planted, isTrue);
      });

      test('returns false when plant is not in the garden', () async {
        // Mirrors: `assertFalse(gardenPlantingDao.isPlanted(testPlants[2].plantId).first())`
        // testPlants[2] = beet (not planted in setUp)
        final bool planted = await gardenPlantingDao.isPlanted('beet');
        expect(planted, isFalse);
      });

      test('returns false for non-existent plant', () async {
        final bool planted =
            await gardenPlantingDao.isPlanted('non-existent');
        expect(planted, isFalse);
      });
    });

    group('watchIsPlanted', () {
      test('emits true when plant is planted', () async {
        final bool planted =
            await gardenPlantingDao.watchIsPlanted('sunflower').first;
        expect(planted, isTrue);
      });

      test('emits false when plant is not planted', () async {
        final bool planted =
            await gardenPlantingDao.watchIsPlanted('beet').first;
        expect(planted, isFalse);
      });

      test('emits updated value when planting is added', () async {
        // Start listening.
        final stream = gardenPlantingDao.watchIsPlanted('apple');

        // Initially not planted.
        expect(await stream.first, isFalse);

        // Add planting.
        await gardenPlantingDao.insertGardenPlanting(
          newGardenPlanting(plantId: 'apple'),
        );

        // Now planted.
        expect(await stream.first, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // testGetPlantAndGardenPlantings
    // Mirrors: @Test fun testGetPlantAndGardenPlantings()
    // -------------------------------------------------------------------------

    group('watchGardenPlantingsWithPlants (join)', () {
      test('returns planted gardens with associated plant data', () async {
        // Mirrors:
        // `val plantAndGardenPlantings = gardenPlantingDao.getPlantedGardens().first()`
        // `assertThat(plantAndGardenPlantings.size, equalTo(1))`
        final plantings =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;
        expect(plantings.length, equals(1));

        // Mirrors:
        // `assertThat(plantAndGardenPlantings[0].plant, equalTo(testPlant))`
        expect(plantings[0].plant.id, equals('sunflower'));
        expect(plantings[0].plant.name, equals('Sunflower'));

        // Mirrors:
        // `assertThat(plantAndGardenPlantings[0].gardenPlantings.size, equalTo(1))`
        // In our model, each row is one GardenPlantingWithPlant.
        expect(plantings[0].gardenPlanting.plantId, equals('sunflower'));
        expect(plantings[0].gardenPlanting.id, equals(testGardenPlantingId));
      });

      test('only shows plants that have been planted', () async {
        // Apple and beet are in the plants table but not planted.
        final plantings =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;

        final plantedIds = plantings.map((p) => p.plant.id).toList();
        expect(plantedIds, contains('sunflower'));
        expect(plantedIds, isNot(contains('apple')));
        expect(plantedIds, isNot(contains('beet')));
      });

      test('returns multiple plantings when multiple plants are planted',
          () async {
        await gardenPlantingDao.insertGardenPlanting(
          newGardenPlanting(
            plantId: 'apple',
            plantDate: testCalendar,
            lastWateringDate: testCalendar,
          ),
        );

        final plantings =
            await gardenPlantingDao.watchGardenPlantingsWithPlants().first;
        expect(plantings.length, equals(2));
      });
    });

    // -------------------------------------------------------------------------
    // watchGardenPlantingsForPlant
    // -------------------------------------------------------------------------

    group('watchGardenPlantingsForPlant', () {
      test('returns plantings for specific plant', () async {
        final List<GardenPlanting> plantings = await gardenPlantingDao
            .watchGardenPlantingsForPlant('sunflower')
            .first;
        expect(plantings.length, equals(1));
        expect(plantings[0].plantId, equals('sunflower'));
      });

      test('returns empty list for unplanted plant', () async {
        final List<GardenPlanting> plantings =
            await gardenPlantingDao.watchGardenPlantingsForPlant('beet').first;
        expect(plantings, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // insertGardenPlanting
    // -------------------------------------------------------------------------

    group('insertGardenPlanting', () {
      test('returns auto-generated id', () async {
        final int id = await gardenPlantingDao.insertGardenPlanting(
          newGardenPlanting(plantId: 'apple'),
        );
        expect(id, greaterThan(0));
      });

      test('stores plantDate and lastWateringDate correctly', () async {
        final DateTime plantDate = DateTime(2024, 1, 15);
        final DateTime lastWatered = DateTime(2024, 6, 1);

        await gardenPlantingDao.insertGardenPlanting(
          newGardenPlanting(
            plantId: 'apple',
            plantDate: plantDate,
            lastWateringDate: lastWatered,
          ),
        );

        final List<GardenPlanting> plantings = await gardenPlantingDao
            .watchGardenPlantingsForPlant('apple')
            .first;
        expect(plantings.length, equals(1));
        expect(plantings[0].plantDate, equals(plantDate));
        expect(plantings[0].lastWateringDate, equals(lastWatered));
      });
    });
  });
}
