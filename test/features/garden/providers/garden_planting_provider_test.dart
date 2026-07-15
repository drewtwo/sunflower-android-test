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

/// Unit tests for [GardenPlantingNotifier] state management.
///
/// Mirrors the Android `GardenPlantingListViewModel` tests. Tests garden
/// state transitions, add/remove planting side effects, and error handling.
///
/// ## Android equivalence
/// The Android `GardenPlantingListViewModel` uses `StateFlow<List<PlantAndGardenPlantings>>`.
/// The Dart equivalent uses [ChangeNotifier] + stream subscriptions.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/garden_planting.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/features/garden/providers/garden_planting_provider.dart';

import '../../../mocks/mock_repositories.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Plant] for testing.
Plant _plant({String id = 'sunflower', String name = 'Sunflower'}) => Plant(
      id: id,
      name: name,
      description: 'A test plant.',
      growZoneNumber: 9,
      wateringInterval: 7,
      imageUrl: '',
    );

/// Creates a [GardenPlanting] for testing.
GardenPlanting _gardenPlanting({String plantId = 'sunflower'}) {
  final DateTime now = DateTime(2024, 6, 15);
  return GardenPlanting(
    id: 1,
    plantId: plantId,
    plantDate: now,
    lastWateringDate: now,
  );
}

/// Creates a [GardenPlantingWithPlant] for testing.
GardenPlantingWithPlant _withPlant({String plantId = 'sunflower'}) =>
    GardenPlantingWithPlant(
      gardenPlanting: _gardenPlanting(plantId: plantId),
      plant: _plant(id: plantId),
    );

void main() {
  late MockGardenPlantingRepository mockRepository;

  setUp(() {
    mockRepository = MockGardenPlantingRepository();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('GardenPlantingNotifier initial state', () {
    test('starts with isLoading = true and empty plantings', () {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());

      final notifier = GardenPlantingNotifier(mockRepository);

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.plantings, isEmpty);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.isEmpty, isTrue);

      notifier.dispose();
    });

    test('subscribes to watchGardenPlantings on creation', () {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());

      final notifier = GardenPlantingNotifier(mockRepository);

      verify(() => mockRepository.watchGardenPlantings()).called(1);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Loading garden plantings
  // -------------------------------------------------------------------------

  group('loading garden plantings', () {
    test('updates state with plantings when stream emits', () async {
      final List<GardenPlantingWithPlant> plantings = [
        _withPlant(plantId: 'sunflower'),
      ];
      final StreamController<List<GardenPlantingWithPlant>> controller =
          StreamController<List<GardenPlantingWithPlant>>();

      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => controller.stream);

      final notifier = GardenPlantingNotifier(mockRepository);

      controller.add(plantings);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.plantings, equals(plantings));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isEmpty, isFalse);

      await controller.close();
      notifier.dispose();
    });

    test('isEmpty is true when garden has no plantings', () async {
      final StreamController<List<GardenPlantingWithPlant>> controller =
          StreamController<List<GardenPlantingWithPlant>>();

      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => controller.stream);

      final notifier = GardenPlantingNotifier(mockRepository);

      controller.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.isLoading, isFalse);

      await controller.close();
      notifier.dispose();
    });

    test('notifies listeners when plantings are updated', () async {
      final StreamController<List<GardenPlantingWithPlant>> controller =
          StreamController<List<GardenPlantingWithPlant>>();

      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => controller.stream);

      final notifier = GardenPlantingNotifier(mockRepository);
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      controller.add([_withPlant()]);
      await Future<void>.delayed(Duration.zero);

      expect(notifyCount, greaterThan(0));

      await controller.close();
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // addPlanting
  // -------------------------------------------------------------------------

  group('addPlanting', () {
    test('calls repository addPlanting with correct plantId', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.addPlanting('sunflower'))
          .thenAnswer((_) async {});

      final notifier = GardenPlantingNotifier(mockRepository);

      await notifier.addPlanting('sunflower');

      verify(() => mockRepository.addPlanting('sunflower')).called(1);

      notifier.dispose();
    });

    test('sets errorMessage when addPlanting throws', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.addPlanting('sunflower'))
          .thenThrow(Exception('DB error'));

      final notifier = GardenPlantingNotifier(mockRepository);

      await notifier.addPlanting('sunflower');

      expect(notifier.state.errorMessage, isNotNull);

      notifier.dispose();
    });

    test('notifies listeners after adding planting', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.addPlanting('sunflower'))
          .thenThrow(Exception('error')); // Triggers notification via error.

      final notifier = GardenPlantingNotifier(mockRepository);
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      await notifier.addPlanting('sunflower');

      expect(notifyCount, greaterThan(0));

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // removePlanting
  // -------------------------------------------------------------------------

  group('removePlanting', () {
    test('calls repository removePlanting with correct plantId', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.removePlanting('sunflower'))
          .thenAnswer((_) async => 1);

      final notifier = GardenPlantingNotifier(mockRepository);

      await notifier.removePlanting('sunflower');

      verify(() => mockRepository.removePlanting('sunflower')).called(1);

      notifier.dispose();
    });

    test('sets errorMessage when removePlanting throws', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.removePlanting('sunflower'))
          .thenThrow(Exception('DB error'));

      final notifier = GardenPlantingNotifier(mockRepository);

      await notifier.removePlanting('sunflower');

      expect(notifier.state.errorMessage, isNotNull);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // removePlantingById
  // -------------------------------------------------------------------------

  group('removePlantingById', () {
    test('calls repository removePlantingById with correct id', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.removePlantingById(42))
          .thenAnswer((_) async => 1);

      final notifier = GardenPlantingNotifier(mockRepository);

      await notifier.removePlantingById(42);

      verify(() => mockRepository.removePlantingById(42)).called(1);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // isPlanted
  // -------------------------------------------------------------------------

  group('isPlanted', () {
    test('returns true when plant is in the garden', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.isPlanted('sunflower'))
          .thenAnswer((_) async => true);

      final notifier = GardenPlantingNotifier(mockRepository);

      final bool result = await notifier.isPlanted('sunflower');

      expect(result, isTrue);
      verify(() => mockRepository.isPlanted('sunflower')).called(1);

      notifier.dispose();
    });

    test('returns false when plant is not in the garden', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.isPlanted('beet'))
          .thenAnswer((_) async => false);

      final notifier = GardenPlantingNotifier(mockRepository);

      final bool result = await notifier.isPlanted('beet');

      expect(result, isFalse);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // clearError
  // -------------------------------------------------------------------------

  group('clearError', () {
    test('removes errorMessage from state', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.addPlanting('sunflower'))
          .thenThrow(Exception('DB error'));

      final notifier = GardenPlantingNotifier(mockRepository);
      await notifier.addPlanting('sunflower');
      expect(notifier.state.errorMessage, isNotNull);

      notifier.clearError();

      expect(notifier.state.errorMessage, isNull);

      notifier.dispose();
    });

    test('notifies listeners when error is cleared', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.addPlanting('sunflower'))
          .thenThrow(Exception('DB error'));

      final notifier = GardenPlantingNotifier(mockRepository);
      await notifier.addPlanting('sunflower');

      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.clearError();

      expect(notifyCount, equals(1));

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('error handling', () {
    test('sets errorMessage when stream emits error', () async {
      when(() => mockRepository.watchGardenPlantings())
          .thenAnswer((_) => Stream.error(Exception('DB error')));

      final notifier = GardenPlantingNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isLoading, isFalse);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // GardenState
  // -------------------------------------------------------------------------

  group('GardenState', () {
    test('isEmpty returns true when plantings is empty', () {
      const state = GardenState(plantings: []);
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when plantings is not empty', () {
      final state = GardenState(plantings: [_withPlant()]);
      expect(state.isEmpty, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = GardenState(
        plantings: [_withPlant()],
        isLoading: false,
        errorMessage: 'error',
      );

      final copy = original.copyWith(isLoading: true);

      expect(copy.plantings, equals(original.plantings));
      expect(copy.isLoading, isTrue);
      expect(copy.errorMessage, equals('error'));
    });

    test('copyWith with clearError removes errorMessage', () {
      const original = GardenState(errorMessage: 'error');
      final copy = original.copyWith(clearError: true);

      expect(copy.errorMessage, isNull);
    });
  });
}
