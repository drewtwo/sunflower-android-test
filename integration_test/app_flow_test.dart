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

/// End-to-end integration tests for the main app flow.
///
/// Tests the complete user journey:
/// 1. App startup and database initialization
/// 2. Navigate to plant list
/// 3. Select plant and view details
/// 4. Add plant to garden
/// 5. View garden screen with planted items
/// 6. Remove plant from garden
///
/// Mirrors the Android `GardenActivityTest.kt` and related instrumented tests.
///
/// ## Running
/// ```sh
/// flutter test integration_test/app_flow_test.dart
/// ```
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';

// ---------------------------------------------------------------------------
// Test database setup
// ---------------------------------------------------------------------------

/// Creates an in-memory [AppDatabase] pre-seeded with test plants.
Future<AppDatabase> _createSeededDatabase() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  // Seed with a small set of test plants.
  await db.plantDao.insertPlants([
    PlantsCompanion.insert(
      id: 'sunflower',
      name: 'Sunflower',
      description:
          'A bright yellow flower that follows the sun. Easy to grow.',
      growZoneNumber: 9,
      wateringInterval: const Value(7),
      imageUrl: const Value(''),
    ),
    PlantsCompanion.insert(
      id: 'apple',
      name: 'Apple',
      description: 'A deciduous tree that produces sweet fruit.',
      growZoneNumber: 5,
      wateringInterval: const Value(3),
      imageUrl: const Value(''),
    ),
    PlantsCompanion.insert(
      id: 'beet',
      name: 'Beet',
      description: 'A root vegetable with edible leaves and roots.',
      growZoneNumber: 7,
      wateringInterval: const Value(5),
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
    database = await _createSeededDatabase();
    plantRepository = PlantRepository(database.plantDao);
    gardenRepository = GardenPlantingRepository(database.gardenPlantingDao);
  });

  tearDown(() async {
    await database.close();
  });

  // -------------------------------------------------------------------------
  // App startup and database initialization
  // -------------------------------------------------------------------------

  group('App startup', () {
    test('database initializes with seeded plants', () async {
      final plants = await plantRepository.watchAllPlants().first;

      expect(plants, isNotEmpty);
      expect(plants.length, equals(3));
    });

    test('plants are sorted alphabetically on startup', () async {
      final plants = await plantRepository.watchAllPlants().first;

      expect(plants[0].name, equals('Apple'));
      expect(plants[1].name, equals('Beet'));
      expect(plants[2].name, equals('Sunflower'));
    });

    test('garden is empty on first launch', () async {
      final plantings = await gardenRepository.watchGardenPlantings().first;
      expect(plantings, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Plant list navigation
  // -------------------------------------------------------------------------

  group('Plant list', () {
    test('all plants are available in the list', () async {
      final plants = await plantRepository.watchAllPlants().first;

      final ids = plants.map((p) => p.id).toSet();
      expect(ids, containsAll(['sunflower', 'apple', 'beet']));
    });

    test('can filter plants by grow zone', () async {
      final zone9Plants =
          await plantRepository.watchPlantsWithGrowZone(9).first;
      expect(zone9Plants.length, equals(1));
      expect(zone9Plants.first.id, equals('sunflower'));

      final zone5Plants =
          await plantRepository.watchPlantsWithGrowZone(5).first;
      expect(zone5Plants.length, equals(1));
      expect(zone5Plants.first.id, equals('apple'));
    });

    test('filter returns empty list for non-existent zone', () async {
      final plants = await plantRepository.watchPlantsWithGrowZone(99).first;
      expect(plants, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Plant detail view
  // -------------------------------------------------------------------------

  group('Plant detail', () {
    test('can retrieve individual plant by id', () async {
      final plant = await plantRepository.getPlantById('sunflower');

      expect(plant, isNotNull);
      expect(plant!.id, equals('sunflower'));
      expect(plant.name, equals('Sunflower'));
      expect(plant.growZoneNumber, equals(9));
      expect(plant.wateringInterval, equals(7));
    });

    test('returns null for non-existent plant id', () async {
      final plant = await plantRepository.getPlantById('non-existent');
      expect(plant, isNull);
    });

    test('plant is not planted initially', () async {
      final isPlanted = await gardenRepository.isPlanted('sunflower');
      expect(isPlanted, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Add plant to garden
  // -------------------------------------------------------------------------

  group('Add plant to garden', () {
    test('can add a plant to the garden', () async {
      // Verify not planted initially.
      expect(await gardenRepository.isPlanted('sunflower'), isFalse);

      // Add to garden.
      await gardenRepository.addPlanting('sunflower');

      // Verify now planted.
      expect(await gardenRepository.isPlanted('sunflower'), isTrue);
    });

    test('garden shows planted plant after adding', () async {
      await gardenRepository.addPlanting('sunflower');

      final plantings = await gardenRepository.watchGardenPlantings().first;

      expect(plantings.length, equals(1));
      expect(plantings.first.plant.id, equals('sunflower'));
      expect(plantings.first.plant.name, equals('Sunflower'));
    });

    test('can add multiple plants to garden', () async {
      await gardenRepository.addPlanting('sunflower');
      await gardenRepository.addPlanting('apple');

      final plantings = await gardenRepository.watchGardenPlantings().first;
      expect(plantings.length, equals(2));

      final plantedIds = plantings.map((p) => p.plant.id).toSet();
      expect(plantedIds, containsAll(['sunflower', 'apple']));
    });

    test('garden planting stores correct plant date', () async {
      final plantDate = DateTime(2024, 6, 15);
      await gardenRepository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: plantDate,
        lastWateringDate: plantDate,
      );

      final plantings = await gardenRepository
          .watchPlantingsForPlant('sunflower')
          .first;

      expect(plantings.length, equals(1));
      expect(plantings.first.plantDate, equals(plantDate));
    });
  });

  // -------------------------------------------------------------------------
  // Garden screen with planted items
  // -------------------------------------------------------------------------

  group('Garden screen', () {
    setUp(() async {
      // Pre-populate garden with two plants.
      await gardenRepository.addPlanting('sunflower');
      await gardenRepository.addPlanting('apple');
    });

    test('garden shows all planted plants', () async {
      final plantings = await gardenRepository.watchGardenPlantings().first;

      expect(plantings.length, equals(2));
    });

    test('garden items contain plant details', () async {
      final plantings = await gardenRepository.watchGardenPlantings().first;

      final sunflowerItem = plantings.firstWhere(
        (p) => p.plant.id == 'sunflower',
      );
      expect(sunflowerItem.plant.name, equals('Sunflower'));
      expect(sunflowerItem.gardenPlanting.plantId, equals('sunflower'));
    });

    test('unplanted plants do not appear in garden', () async {
      final plantings = await gardenRepository.watchGardenPlantings().first;

      final plantedIds = plantings.map((p) => p.plant.id).toSet();
      expect(plantedIds, isNot(contains('beet')));
    });
  });

  // -------------------------------------------------------------------------
  // Remove plant from garden
  // -------------------------------------------------------------------------

  group('Remove plant from garden', () {
    setUp(() async {
      await gardenRepository.addPlanting('sunflower');
      await gardenRepository.addPlanting('apple');
    });

    test('can remove a plant from the garden', () async {
      // Verify planted.
      expect(await gardenRepository.isPlanted('sunflower'), isTrue);

      // Remove from garden.
      await gardenRepository.removePlanting('sunflower');

      // Verify no longer planted.
      expect(await gardenRepository.isPlanted('sunflower'), isFalse);
    });

    test('garden count decreases after removal', () async {
      final before = await gardenRepository.watchGardenPlantings().first;
      expect(before.length, equals(2));

      await gardenRepository.removePlanting('sunflower');

      final after = await gardenRepository.watchGardenPlantings().first;
      expect(after.length, equals(1));
    });

    test('remaining plants stay in garden after removal', () async {
      await gardenRepository.removePlanting('sunflower');

      final plantings = await gardenRepository.watchGardenPlantings().first;
      expect(plantings.length, equals(1));
      expect(plantings.first.plant.id, equals('apple'));
    });

    test('removing non-existent plant returns 0', () async {
      final result = await gardenRepository.removePlanting('beet');
      expect(result, equals(0));
    });

    test('garden is empty after removing all plants', () async {
      await gardenRepository.removePlanting('sunflower');
      await gardenRepository.removePlanting('apple');

      final plantings = await gardenRepository.watchGardenPlantings().first;
      expect(plantings, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Stream reactivity
  // -------------------------------------------------------------------------

  group('Stream reactivity', () {
    test('garden stream emits update when plant is added', () async {
      final stream = gardenRepository.watchGardenPlantings();

      // Initially empty.
      final initial = await stream.first;
      expect(initial, isEmpty);

      // Add a plant.
      await gardenRepository.addPlanting('sunflower');

      // Stream should emit updated list.
      final updated = await stream.first;
      expect(updated.length, equals(1));
    });

    test('isPlanted stream emits update when plant is added', () async {
      final stream = gardenRepository.watchIsPlanted('sunflower');

      // Initially not planted.
      expect(await stream.first, isFalse);

      // Add plant.
      await gardenRepository.addPlanting('sunflower');

      // Now planted.
      expect(await stream.first, isTrue);
    });

    test('plant list stream emits update when plant is inserted', () async {
      final stream = plantRepository.watchAllPlants();

      final initial = await stream.first;
      expect(initial.length, equals(3));

      // Insert a new plant.
      await database.plantDao.insertPlants([
        PlantsCompanion.insert(
          id: 'tomato',
          name: 'Tomato',
          description: 'A red vegetable.',
          growZoneNumber: 1,
        ),
      ]);

      final updated = await stream.first;
      expect(updated.length, equals(4));
    });
  });
}
