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

/// Unit tests for [PlantDetailNotifier] state management.
///
/// Mirrors the Android `PlantDetailViewModel` tests. Tests single plant
/// queries, isPlanted status, addToGarden action, and error handling.
///
/// ## Android equivalence
/// The Android `PlantDetailViewModel` uses `LiveData<Plant>` and
/// `LiveData<Boolean>` for isPlanted. The Dart equivalent uses
/// [ChangeNotifier] + stream subscriptions.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/features/plant_detail/providers/plant_detail_provider.dart';

import '../../../mocks/mock_repositories.dart';

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

/// Creates a [PlantDetailNotifier] with mocked dependencies.
PlantDetailNotifier _createNotifier({
  required MockPlantRepository plantRepo,
  required MockGardenPlantingRepository gardenRepo,
  String plantId = 'sunflower',
}) =>
    PlantDetailNotifier(
      plantId: plantId,
      plantRepository: plantRepo,
      gardenPlantingRepository: gardenRepo,
    );

void main() {
  late MockPlantRepository mockPlantRepo;
  late MockGardenPlantingRepository mockGardenRepo;

  setUp(() {
    mockPlantRepo = MockPlantRepository();
    mockGardenRepo = MockGardenPlantingRepository();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('PlantDetailNotifier initial state', () {
    test('starts with isLoading = true and no plant', () {
      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => const Stream.empty());

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );

      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.plant, isNull);
      expect(notifier.state.isPlanted, isFalse);
      expect(notifier.state.errorMessage, isNull);

      notifier.dispose();
    });

    test('subscribes to plant and isPlanted streams on creation', () {
      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => const Stream.empty());

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );

      verify(() => mockPlantRepo.watchPlantById('sunflower')).called(1);
      verify(() => mockGardenRepo.watchIsPlanted('sunflower')).called(1);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Loading plant data
  // -------------------------------------------------------------------------

  group('loading plant data', () {
    test('updates state with plant when stream emits', () async {
      final Plant plant = _plant();
      final StreamController<Plant?> plantController =
          StreamController<Plant?>();
      final StreamController<bool> isPlantedController =
          StreamController<bool>();

      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => plantController.stream);
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => isPlantedController.stream);

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );

      // Emit plant data.
      plantController.add(plant);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.plant, equals(plant));
      expect(notifier.state.isLoading, isFalse);

      await plantController.close();
      await isPlantedController.close();
      notifier.dispose();
    });

    test('handles null plant (not found)', () async {
      final StreamController<Plant?> plantController =
          StreamController<Plant?>();

      when(() => mockPlantRepo.watchPlantById('unknown'))
          .thenAnswer((_) => plantController.stream);
      when(() => mockGardenRepo.watchIsPlanted('unknown'))
          .thenAnswer((_) => const Stream.empty());

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
        plantId: 'unknown',
      );

      plantController.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.plant, isNull);
      expect(notifier.state.isLoading, isFalse);

      await plantController.close();
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // isPlanted status
  // -------------------------------------------------------------------------

  group('isPlanted status', () {
    test('updates isPlanted when stream emits true', () async {
      final StreamController<Plant?> plantController =
          StreamController<Plant?>();
      final StreamController<bool> isPlantedController =
          StreamController<bool>();

      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => plantController.stream);
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => isPlantedController.stream);

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );

      expect(notifier.state.isPlanted, isFalse);

      isPlantedController.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isPlanted, isTrue);

      await plantController.close();
      await isPlantedController.close();
      notifier.dispose();
    });

    test('updates isPlanted when stream emits false', () async {
      final StreamController<Plant?> plantController =
          StreamController<Plant?>();
      final StreamController<bool> isPlantedController =
          StreamController<bool>();

      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => plantController.stream);
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => isPlantedController.stream);

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );

      isPlantedController.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isPlanted, isTrue);

      isPlantedController.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isPlanted, isFalse);

      await plantController.close();
      await isPlantedController.close();
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // addToGarden
  // -------------------------------------------------------------------------

  group('addToGarden', () {
    test('calls repository addPlanting when plant is not planted', () async {
      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => Stream.value(_plant()));
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => Stream.value(false));
      when(() => mockGardenRepo.addPlanting('sunflower'))
          .thenAnswer((_) async {});

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.addToGarden();

      verify(() => mockGardenRepo.addPlanting('sunflower')).called(1);

      notifier.dispose();
    });

    test('does not call addPlanting when plant is already planted', () async {
      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => Stream.value(_plant()));
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => Stream.value(true));

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.addToGarden();

      verifyNever(() => mockGardenRepo.addPlanting(any()));

      notifier.dispose();
    });

    test('sets errorMessage when addPlanting throws', () async {
      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => Stream.value(_plant()));
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => Stream.value(false));
      when(() => mockGardenRepo.addPlanting('sunflower'))
          .thenThrow(Exception('DB error'));

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.addToGarden();

      expect(notifier.state.errorMessage, isNotNull);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('error handling', () {
    test('sets errorMessage when plant stream emits error', () async {
      when(() => mockPlantRepo.watchPlantById('sunflower'))
          .thenAnswer((_) => Stream.error(Exception('DB error')));
      when(() => mockGardenRepo.watchIsPlanted('sunflower'))
          .thenAnswer((_) => const Stream.empty());

      final notifier = _createNotifier(
        plantRepo: mockPlantRepo,
        gardenRepo: mockGardenRepo,
      );
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isLoading, isFalse);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // PlantDetailState
  // -------------------------------------------------------------------------

  group('PlantDetailState', () {
    test('copyWith preserves unchanged fields', () {
      final plant = _plant();
      final original = PlantDetailState(
        plant: plant,
        isPlanted: true,
        isLoading: false,
        errorMessage: 'error',
      );

      final copy = original.copyWith(isLoading: true);

      expect(copy.plant, equals(plant));
      expect(copy.isPlanted, isTrue);
      expect(copy.isLoading, isTrue);
      expect(copy.errorMessage, equals('error'));
    });

    test('copyWith with clearError removes errorMessage', () {
      const original = PlantDetailState(errorMessage: 'error');
      final copy = original.copyWith(clearError: true);

      expect(copy.errorMessage, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // createPlantDetailNotifier factory
  // -------------------------------------------------------------------------

  group('createPlantDetailNotifier', () {
    test('creates notifier with correct plantId', () {
      when(() => mockPlantRepo.watchPlantById('apple'))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockGardenRepo.watchIsPlanted('apple'))
          .thenAnswer((_) => const Stream.empty());

      final notifier = createPlantDetailNotifier(
        'apple',
        plantRepository: mockPlantRepo,
        gardenPlantingRepository: mockGardenRepo,
      );

      verify(() => mockPlantRepo.watchPlantById('apple')).called(1);

      notifier.dispose();
    });
  });
}
