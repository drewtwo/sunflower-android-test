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

/// Provider-based state management for the garden feature.
///
/// Mirrors the Android `GardenPlantingListViewModel` defined in
/// `viewmodels/GardenPlantingListViewModel.kt` and the garden-related
/// operations from `PlantDetailViewModel`.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@HiltViewModel`                  | `ChangeNotifier` + `ChangeNotifierProvider` |
/// | `StateFlow<List<PlantAndGardenPlantings>>` | `List<GardenPlantingWithPlant>` |
/// | `gardenPlantingRepository.getPlantedGardens()` | `watchGardenPlantings()` |
/// | `suspend fun createGardenPlanting` | `Future<void> addPlanting(...)`    |
/// | `suspend fun removeGardenPlanting` | `Future<void> removePlanting(...)` |
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Represents the state of the garden screen.
class GardenState {
  /// Creates a [GardenState].
  const GardenState({
    this.plantings = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  /// The list of garden plantings with their associated plant data.
  final List<GardenPlantingWithPlant> plantings;

  /// Whether the garden data is currently loading.
  final bool isLoading;

  /// An error message, or `null` if there is no error.
  final String? errorMessage;

  /// Returns `true` if the garden is empty.
  bool get isEmpty => plantings.isEmpty;

  /// Returns a copy of this state with the given fields replaced.
  GardenState copyWith({
    List<GardenPlantingWithPlant>? plantings,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      GardenState(
        plantings: plantings ?? this.plantings,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for the garden screen.
///
/// Mirrors the Android `GardenPlantingListViewModel` class. Observes all
/// garden plantings and provides actions to add/remove plants.
///
/// ## Usage
/// ```dart
/// final notifier = GardenPlantingNotifier(
///   repository: getIt<GardenPlantingRepository>(),
/// );
/// await notifier.addPlanting('sunflower');
/// ```
class GardenPlantingNotifier extends ChangeNotifier {
  /// Creates a [GardenPlantingNotifier] with the given [_repository].
  GardenPlantingNotifier(this._repository) {
    _subscribeToGardenPlantings();
  }

  final GardenPlantingRepository _repository;

  GardenState _state = const GardenState();
  StreamSubscription<List<GardenPlantingWithPlant>>? _plantingsSubscription;

  /// The current state of the garden.
  GardenState get state => _state;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Adds a planting for the plant with [plantId] to the garden.
  ///
  /// Mirrors `suspend fun createGardenPlanting(plantId: String)` in
  /// `GardenPlantingRepository`.
  Future<void> addPlanting(String plantId) async {
    try {
      await _repository.addPlanting(plantId);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  /// Removes the planting for the plant with [plantId] from the garden.
  ///
  /// Mirrors `suspend fun removeGardenPlanting(gardenPlanting: GardenPlanting)`
  /// in `GardenPlantingRepository`.
  Future<void> removePlanting(String plantId) async {
    try {
      await _repository.removePlanting(plantId);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  /// Removes the planting with the given [id] from the garden.
  Future<void> removePlantingById(int id) async {
    try {
      await _repository.removePlantingById(id);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  /// Checks whether the plant with [plantId] is currently in the garden.
  ///
  /// Returns `true` if the plant is planted.
  Future<bool> isPlanted(String plantId) => _repository.isPlanted(plantId);

  /// Clears any error message from the state.
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _subscribeToGardenPlantings() {
    _plantingsSubscription = _repository.watchGardenPlantings().listen(
      (plantings) {
        _state = _state.copyWith(
          plantings: plantings,
          isLoading: false,
          clearError: true,
        );
        notifyListeners();
      },
      onError: (Object error) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _plantingsSubscription?.cancel();
    super.dispose();
  }
}
