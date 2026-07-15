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

/// Unit tests for [PlantListNotifier] state management.
///
/// Mirrors the Android `PlantListViewModel` tests. Tests state transitions
/// for grow zone filtering, loading states, and error handling.
///
/// ## Android equivalence
/// The Android `PlantListViewModel` uses `StateFlow` + `flatMapLatest`.
/// The Dart equivalent uses [ChangeNotifier] + stream subscriptions.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/features/plant_list/providers/plant_list_provider.dart';

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

void main() {
  late MockPlantRepository mockRepository;

  setUp(() {
    mockRepository = MockPlantRepository();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('PlantListNotifier initial state', () {
    test('starts with isLoading = true and empty plants list', () {
      // Arrange — stub the repository to return a never-completing stream.
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());

      // Act
      final notifier = PlantListNotifier(mockRepository);

      // Assert — initial state before stream emits.
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.plants, isEmpty);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.growZone, equals(noFilterGrowZone));
      expect(notifier.state.isFiltered, isFalse);

      notifier.dispose();
    });

    test('subscribes to watchAllPlants on creation', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);

      verify(() => mockRepository.watchAllPlants()).called(1);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Loading plants
  // -------------------------------------------------------------------------

  group('PlantListNotifier loading plants', () {
    test('updates state with plants when stream emits', () async {
      // Arrange
      final List<Plant> plants = [
        _plant(id: 'apple', name: 'Apple'),
        _plant(id: 'sunflower', name: 'Sunflower'),
      ];
      final StreamController<List<Plant>> controller =
          StreamController<List<Plant>>();

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => controller.stream);

      final notifier = PlantListNotifier(mockRepository);

      // Act — emit plants from the stream.
      controller.add(plants);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.state.plants, equals(plants));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);

      await controller.close();
      notifier.dispose();
    });

    test('sets isLoading = false after receiving plants', () async {
      final StreamController<List<Plant>> controller =
          StreamController<List<Plant>>();

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => controller.stream);

      final notifier = PlantListNotifier(mockRepository);
      expect(notifier.state.isLoading, isTrue);

      controller.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);

      await controller.close();
      notifier.dispose();
    });

    test('notifies listeners when plants are updated', () async {
      final StreamController<List<Plant>> controller =
          StreamController<List<Plant>>();

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => controller.stream);

      final notifier = PlantListNotifier(mockRepository);
      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      controller.add([_plant()]);
      await Future<void>.delayed(Duration.zero);

      expect(notifyCount, greaterThan(0));

      await controller.close();
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // setGrowZone
  // -------------------------------------------------------------------------

  group('setGrowZone', () {
    test('switches to filtered stream when zone is set', () async {
      // Arrange
      final List<Plant> allPlants = [
        _plant(id: 'apple', name: 'Apple', growZoneNumber: 5),
        _plant(id: 'sunflower', name: 'Sunflower', growZoneNumber: 9),
      ];
      final List<Plant> zone9Plants = [
        _plant(id: 'sunflower', name: 'Sunflower', growZoneNumber: 9),
      ];

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => Stream.value(allPlants));
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => Stream.value(zone9Plants));

      final notifier = PlantListNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      // Act
      notifier.setGrowZone(9);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.state.growZone, equals(9));
      expect(notifier.state.isFiltered, isTrue);
      expect(notifier.state.plants, equals(zone9Plants));
      verify(() => mockRepository.watchPlantsWithGrowZone(9)).called(1);

      notifier.dispose();
    });

    test('does not re-subscribe when same zone is set again', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);
      notifier.setGrowZone(9);
      notifier.setGrowZone(9); // Same zone — should not re-subscribe.

      verify(() => mockRepository.watchPlantsWithGrowZone(9)).called(1);

      notifier.dispose();
    });

    test('updates isFiltered to true', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.watchPlantsWithGrowZone(5))
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);
      expect(notifier.state.isFiltered, isFalse);

      notifier.setGrowZone(5);

      expect(notifier.state.isFiltered, isTrue);
      expect(notifier.state.growZone, equals(5));

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // clearGrowZone
  // -------------------------------------------------------------------------

  group('clearGrowZone', () {
    test('clears filter and switches back to all-plants stream', () async {
      // Arrange
      final List<Plant> allPlants = [_plant(), _plant(id: 'apple')];
      final List<Plant> zone9Plants = [_plant()];

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => Stream.value(allPlants));
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => Stream.value(zone9Plants));

      final notifier = PlantListNotifier(mockRepository);
      notifier.setGrowZone(9);
      await Future<void>.delayed(Duration.zero);

      // Act
      notifier.clearGrowZone();
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(notifier.state.growZone, equals(noFilterGrowZone));
      expect(notifier.state.isFiltered, isFalse);
      expect(notifier.state.plants, equals(allPlants));

      notifier.dispose();
    });

    test('does nothing when no filter is active', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);
      notifier.clearGrowZone(); // Should be a no-op.

      // watchAllPlants should only be called once (from constructor).
      verify(() => mockRepository.watchAllPlants()).called(1);

      notifier.dispose();
    });

    test('sets isFiltered to false', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);
      notifier.setGrowZone(9);
      expect(notifier.state.isFiltered, isTrue);

      notifier.clearGrowZone();
      expect(notifier.state.isFiltered, isFalse);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // toggleFilter
  // -------------------------------------------------------------------------

  group('toggleFilter', () {
    test('sets zone to 9 when no filter is active', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);
      expect(notifier.state.isFiltered, isFalse);

      notifier.toggleFilter();

      expect(notifier.state.isFiltered, isTrue);
      expect(notifier.state.growZone, equals(9));

      notifier.dispose();
    });

    test('clears filter when filter is active', () {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepository.watchPlantsWithGrowZone(9))
          .thenAnswer((_) => const Stream.empty());

      final notifier = PlantListNotifier(mockRepository);
      notifier.setGrowZone(9);
      expect(notifier.state.isFiltered, isTrue);

      notifier.toggleFilter();

      expect(notifier.state.isFiltered, isFalse);

      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('error handling', () {
    test('sets errorMessage when stream emits an error', () async {
      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => Stream.error(Exception('DB error')));

      final notifier = PlantListNotifier(mockRepository);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.errorMessage, isNotNull);
      expect(notifier.state.isLoading, isFalse);

      notifier.dispose();
    });

    test('clears errorMessage when new data arrives after error', () async {
      final StreamController<List<Plant>> controller =
          StreamController<List<Plant>>();

      when(() => mockRepository.watchAllPlants())
          .thenAnswer((_) => controller.stream);

      final notifier = PlantListNotifier(mockRepository);

      // Emit an error.
      controller.addError(Exception('DB error'));
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.errorMessage, isNotNull);

      // Emit valid data.
      controller.add([_plant()]);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.errorMessage, isNull);

      await controller.close();
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // PlantListState
  // -------------------------------------------------------------------------

  group('PlantListState', () {
    test('isFiltered returns false when growZone is noFilterGrowZone', () {
      const state = PlantListState(growZone: noFilterGrowZone);
      expect(state.isFiltered, isFalse);
    });

    test('isFiltered returns true when growZone is set', () {
      const state = PlantListState(growZone: 9);
      expect(state.isFiltered, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const original = PlantListState(
        isLoading: false,
        growZone: 9,
        errorMessage: 'error',
      );
      final copy = original.copyWith(isLoading: true);

      expect(copy.isLoading, isTrue);
      expect(copy.growZone, equals(9));
      expect(copy.errorMessage, equals('error'));
    });

    test('copyWith with clearError removes errorMessage', () {
      const original = PlantListState(errorMessage: 'error');
      final copy = original.copyWith(clearError: true);

      expect(copy.errorMessage, isNull);
    });
  });
}
