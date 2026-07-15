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

/// Unit tests for [GardenPlantingRepository].
///
/// Uses [mocktail] to mock [GardenPlantingDao] and verifies that the
/// repository correctly delegates to the DAO for all operations.
///
/// Mirrors the Android `GardenPlantingDaoTest.kt` logic at the repository
/// layer, testing add/remove operations, isPlanted checks, and stream
/// emissions.
library;

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';

import '../../mocks/mock_repositories.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Plant] for testing.
Plant _plant({
  String id = 'sunflower',
  String name = 'Sunflower',
  int growZoneNumber = 9,
}) =>
    Plant(
      id: id,
      name: name,
      description: 'A test plant.',
      growZoneNumber: growZoneNumber,
      wateringInterval: 7,
      imageUrl: '',
    );

/// Creates a [GardenPlanting] for testing.
GardenPlanting _gardenPlanting({
  int id = 1,
  String plantId = 'sunflower',
}) {
  final DateTime now = DateTime(2024, 6, 15);
  return GardenPlanting(
    id: id,
    plantId: plantId,
    plantDate: now,
    lastWateringDate: now,
  );
}

/// Creates a [GardenPlantingWithPlant] for testing.
GardenPlantingWithPlant _gardenPlantingWithPlant({
  String plantId = 'sunflower',
}) =>
    GardenPlantingWithPlant(
      gardenPlanting: _gardenPlanting(plantId: plantId),
      plant: _plant(id: plantId),
    );

void main() {
  late MockGardenPlantingDao mockDao;
  late GardenPlantingRepository repository;

  setUp(() {
    mockDao = MockGardenPlantingDao();
    repository = GardenPlantingRepository(mockDao);
  });

  // -------------------------------------------------------------------------
  // addPlanting
  // -------------------------------------------------------------------------

  group('addPlanting', () {
    test('inserts a new garden planting via DAO', () async {
      // Arrange
      when(
        () => mockDao.insertGardenPlanting(any()),
      ).thenAnswer((_) async => 1);

      // Act
      await repository.addPlanting('sunflower');

      // Assert — verify DAO was called with a companion for 'sunflower'.
      verify(() => mockDao.insertGardenPlanting(any())).called(1);
    });

    test('propagates exceptions from DAO', () async {
      when(
        () => mockDao.insertGardenPlanting(any()),
      ).thenThrow(Exception('DB error'));

      expect(
        () => repository.addPlanting('sunflower'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // addPlantingWithDates
  // -------------------------------------------------------------------------

  group('addPlantingWithDates', () {
    test('inserts planting with explicit dates', () async {
      when(
        () => mockDao.insertGardenPlanting(any()),
      ).thenAnswer((_) async => 1);

      final DateTime plantDate = DateTime(2024, 1, 1);
      final DateTime lastWatered = DateTime(2024, 6, 15);

      await repository.addPlantingWithDates(
        plantId: 'sunflower',
        plantDate: plantDate,
        lastWateringDate: lastWatered,
      );

      verify(() => mockDao.insertGardenPlanting(any())).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // removePlanting
  // -------------------------------------------------------------------------

  group('removePlanting', () {
    test('deletes garden planting via DAO', () async {
      when(
        () => mockDao.deleteGardenPlanting('sunflower'),
      ).thenAnswer((_) async => 1);

      final int result = await repository.removePlanting('sunflower');

      expect(result, equals(1));
      verify(() => mockDao.deleteGardenPlanting('sunflower')).called(1);
    });

    test('returns 0 when planting does not exist', () async {
      when(
        () => mockDao.deleteGardenPlanting('non-existent'),
      ).thenAnswer((_) async => 0);

      final int result = await repository.removePlanting('non-existent');

      expect(result, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // removePlantingById
  // -------------------------------------------------------------------------

  group('removePlantingById', () {
    test('deletes planting by id via DAO', () async {
      when(
        () => mockDao.deleteGardenPlantingById(42),
      ).thenAnswer((_) async => 1);

      final int result = await repository.removePlantingById(42);

      expect(result, equals(1));
      verify(() => mockDao.deleteGardenPlantingById(42)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // isPlanted
  // -------------------------------------------------------------------------

  group('isPlanted', () {
    test('returns true when plant is in the garden', () async {
      when(
        () => mockDao.isPlanted('sunflower'),
      ).thenAnswer((_) async => true);

      final bool result = await repository.isPlanted('sunflower');

      expect(result, isTrue);
      verify(() => mockDao.isPlanted('sunflower')).called(1);
    });

    test('returns false when plant is not in the garden', () async {
      when(
        () => mockDao.isPlanted('beet'),
      ).thenAnswer((_) async => false);

      final bool result = await repository.isPlanted('beet');

      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // watchIsPlanted
  // -------------------------------------------------------------------------

  group('watchIsPlanted', () {
    test('returns stream of true when plant is planted', () {
      when(
        () => mockDao.watchIsPlanted('sunflower'),
      ).thenAnswer((_) => Stream.value(true));

      expect(repository.watchIsPlanted('sunflower'), emits(isTrue));
      verify(() => mockDao.watchIsPlanted('sunflower')).called(1);
    });

    test('returns stream of false when plant is not planted', () {
      when(
        () => mockDao.watchIsPlanted('beet'),
      ).thenAnswer((_) => Stream.value(false));

      expect(repository.watchIsPlanted('beet'), emits(isFalse));
    });

    test('emits multiple values as planting status changes', () {
      when(
        () => mockDao.watchIsPlanted('apple'),
      ).thenAnswer((_) => Stream.fromIterable([false, true]));

      expect(
        repository.watchIsPlanted('apple'),
        emitsInOrder([false, true]),
      );
    });

    test('propagates errors from DAO', () {
      when(
        () => mockDao.watchIsPlanted('error-plant'),
      ).thenAnswer((_) => Stream.error(Exception('DB error')));

      expect(
        repository.watchIsPlanted('error-plant'),
        emitsError(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // watchGardenPlantings
  // -------------------------------------------------------------------------

  group('watchGardenPlantings', () {
    test('returns stream of all garden plantings with plant data', () {
      final List<GardenPlantingWithPlant> plantings = [
        _gardenPlantingWithPlant(plantId: 'sunflower'),
      ];
      when(
        () => mockDao.watchGardenPlantingsWithPlants(),
      ).thenAnswer((_) => Stream.value(plantings));

      expect(repository.watchGardenPlantings(), emits(plantings));
      verify(() => mockDao.watchGardenPlantingsWithPlants()).called(1);
    });

    test('emits empty list when garden is empty', () {
      when(
        () => mockDao.watchGardenPlantingsWithPlants(),
      ).thenAnswer((_) => Stream.value([]));

      expect(repository.watchGardenPlantings(), emits(isEmpty));
    });

    test('emits multiple updates as garden changes', () {
      final List<GardenPlantingWithPlant> initial = [];
      final List<GardenPlantingWithPlant> updated = [
        _gardenPlantingWithPlant(plantId: 'sunflower'),
      ];

      when(
        () => mockDao.watchGardenPlantingsWithPlants(),
      ).thenAnswer((_) => Stream.fromIterable([initial, updated]));

      expect(
        repository.watchGardenPlantings(),
        emitsInOrder([initial, updated]),
      );
    });

    test('propagates errors from DAO', () {
      when(
        () => mockDao.watchGardenPlantingsWithPlants(),
      ).thenAnswer((_) => Stream.error(Exception('DB error')));

      expect(
        repository.watchGardenPlantings(),
        emitsError(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // watchPlantingsForPlant
  // -------------------------------------------------------------------------

  group('watchPlantingsForPlant', () {
    test('returns stream of plantings for specific plant', () {
      final List<GardenPlanting> plantings = [
        _gardenPlanting(plantId: 'sunflower'),
      ];
      when(
        () => mockDao.watchGardenPlantingsForPlant('sunflower'),
      ).thenAnswer((_) => Stream.value(plantings));

      expect(repository.watchPlantingsForPlant('sunflower'), emits(plantings));
      verify(
        () => mockDao.watchGardenPlantingsForPlant('sunflower'),
      ).called(1);
    });

    test('returns empty stream for unplanted plant', () {
      when(
        () => mockDao.watchGardenPlantingsForPlant('beet'),
      ).thenAnswer((_) => Stream.value([]));

      expect(repository.watchPlantingsForPlant('beet'), emits(isEmpty));
    });
  });
}
