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

/// Unit tests for [PlantRepository].
///
/// Mirrors the Android `data/PlantDaoTest.kt` and related repository tests.
/// Uses [mocktail] to mock [PlantDao] and verifies that the repository
/// correctly delegates to the DAO.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';

import '../../mocks/mock_repositories.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Plant] for testing.
Plant _plant({
  String id = 'sunflower',
  String name = 'Sunflower',
  int growZoneNumber = 9,
  int wateringInterval = 7,
}) =>
    Plant(
      id: id,
      name: name,
      description: 'A test plant.',
      growZoneNumber: growZoneNumber,
      wateringInterval: wateringInterval,
      imageUrl: '',
    );

void main() {
  late MockPlantDao mockDao;
  late PlantRepository repository;

  setUp(() {
    mockDao = MockPlantDao();
    repository = PlantRepository(mockDao);
  });

  // -------------------------------------------------------------------------
  // watchAllPlants
  // -------------------------------------------------------------------------

  group('watchAllPlants', () {
    test('delegates to PlantDao.watchAllPlants and returns stream', () {
      // Arrange
      final List<Plant> plants = [
        _plant(id: 'apple', name: 'Apple'),
        _plant(id: 'sunflower', name: 'Sunflower'),
      ];
      when(() => mockDao.watchAllPlants())
          .thenAnswer((_) => Stream.value(plants));

      // Act
      final Stream<List<Plant>> stream = repository.watchAllPlants();

      // Assert
      expect(stream, emits(plants));
      verify(() => mockDao.watchAllPlants()).called(1);
    });

    test('emits empty list when no plants exist', () {
      when(() => mockDao.watchAllPlants())
          .thenAnswer((_) => Stream.value([]));

      expect(repository.watchAllPlants(), emits(isEmpty));
    });

    test('propagates errors from DAO', () {
      when(() => mockDao.watchAllPlants())
          .thenAnswer((_) => Stream.error(Exception('DB error')));

      expect(
        repository.watchAllPlants(),
        emitsError(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // watchPlantById
  // -------------------------------------------------------------------------

  group('watchPlantById', () {
    test('returns stream of plant when found', () {
      final Plant plant = _plant(id: 'sunflower');
      when(() => mockDao.watchPlantById('sunflower'))
          .thenAnswer((_) => Stream.value(plant));

      expect(repository.watchPlantById('sunflower'), emits(plant));
      verify(() => mockDao.watchPlantById('sunflower')).called(1);
    });

    test('returns stream of null when plant not found', () {
      when(() => mockDao.watchPlantById('unknown'))
          .thenAnswer((_) => Stream.value(null));

      expect(repository.watchPlantById('unknown'), emits(isNull));
    });
  });

  // -------------------------------------------------------------------------
  // getPlantById
  // -------------------------------------------------------------------------

  group('getPlantById', () {
    test('returns plant when found', () async {
      final Plant plant = _plant(id: 'sunflower');
      when(() => mockDao.getPlantById('sunflower'))
          .thenAnswer((_) async => plant);

      final Plant? result = await repository.getPlantById('sunflower');

      expect(result, equals(plant));
      verify(() => mockDao.getPlantById('sunflower')).called(1);
    });

    test('returns null when plant not found', () async {
      when(() => mockDao.getPlantById('unknown'))
          .thenAnswer((_) async => null);

      final Plant? result = await repository.getPlantById('unknown');

      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // watchPlantsWithGrowZone
  // -------------------------------------------------------------------------

  group('watchPlantsWithGrowZone', () {
    test('delegates to DAO with correct zone number', () {
      final List<Plant> zone9Plants = [_plant(growZoneNumber: 9)];
      when(() => mockDao.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => Stream.value(zone9Plants));

      final Stream<List<Plant>> stream =
          repository.watchPlantsWithGrowZone(9);

      expect(stream, emits(zone9Plants));
      verify(() => mockDao.watchPlantsWithGrowZone(9)).called(1);
    });

    test('emits empty list when no plants match zone', () {
      when(() => mockDao.watchPlantsWithGrowZone(13))
          .thenAnswer((_) => Stream.value([]));

      expect(repository.watchPlantsWithGrowZone(13), emits(isEmpty));
    });

    test('emits multiple updates when data changes', () async {
      final List<Plant> initial = [_plant(id: 'a', growZoneNumber: 5)];
      final List<Plant> updated = [
        _plant(id: 'a', growZoneNumber: 5),
        _plant(id: 'b', growZoneNumber: 5),
      ];

      // Simulate two emissions from the DAO.
      when(() => mockDao.watchPlantsWithGrowZone(5)).thenAnswer(
        (_) => Stream.fromIterable([initial, updated]),
      );

      expect(
        repository.watchPlantsWithGrowZone(5),
        emitsInOrder([initial, updated]),
      );
    });
  });
}
