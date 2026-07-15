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

/// Provider-based state management for the plant detail feature.
///
/// Mirrors the Android `PlantDetailViewModel` defined in
/// `viewmodels/PlantDetailViewModel.kt`.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@HiltViewModel`                  | `ChangeNotifier` + `ChangeNotifierProvider` |
/// | `val plant: LiveData<Plant>`      | `Plant? get plant`                  |
/// | `val isPlanted: LiveData<Boolean>`| `bool get isPlanted`                |
/// | `fun addPlantToGarden()`          | `Future<void> addToGarden()`        |
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Represents the state of the plant detail screen.
class PlantDetailState {
  /// Creates a [PlantDetailState].
  const PlantDetailState({
    this.plant,
    this.isPlanted = false,
    this.isLoading = true,
    this.errorMessage,
  });

  /// The plant being displayed, or `null` if not yet loaded.
  final Plant? plant;

  /// Whether this plant is currently in the user's garden.
  final bool isPlanted;

  /// Whether the plant data is currently loading.
  final bool isLoading;

  /// An error message, or `null` if there is no error.
  final String? errorMessage;

  /// Returns a copy of this state with the given fields replaced.
  PlantDetailState copyWith({
    Plant? plant,
    bool? isPlanted,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      PlantDetailState(
        plant: plant ?? this.plant,
        isPlanted: isPlanted ?? this.isPlanted,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for the plant detail screen.
///
/// Mirrors the Android `PlantDetailViewModel` class. Observes a single plant
/// and its planting status, and provides an action to add the plant to the
/// garden.
///
/// ## Usage
/// ```dart
/// // Create with a specific plant ID:
/// final notifier = PlantDetailNotifier(
///   plantId: 'sunflower',
///   plantRepository: getIt<PlantRepository>(),
///   gardenPlantingRepository: getIt<GardenPlantingRepository>(),
/// );
/// ```
class PlantDetailNotifier extends ChangeNotifier {
  /// Creates a [PlantDetailNotifier] for the plant with [plantId].
  PlantDetailNotifier({
    required String plantId,
    required PlantRepository plantRepository,
    required GardenPlantingRepository gardenPlantingRepository,
  })  : _plantId = plantId,
        _plantRepository = plantRepository,
        _gardenPlantingRepository = gardenPlantingRepository {
    _subscribeToPlant();
    _subscribeToIsPlanted();
  }

  final String _plantId;
  final PlantRepository _plantRepository;
  final GardenPlantingRepository _gardenPlantingRepository;

  PlantDetailState _state = const PlantDetailState();
  StreamSubscription<Plant?>? _plantSubscription;
  StreamSubscription<bool>? _isPlantedSubscription;

  /// The current state of the plant detail screen.
  PlantDetailState get state => _state;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Adds this plant to the user's garden.
  ///
  /// Mirrors `fun addPlantToGarden()` in the Android `PlantDetailViewModel`.
  /// No-op if the plant is already planted.
  Future<void> addToGarden() async {
    if (_state.isPlanted) return;
    try {
      await _gardenPlantingRepository.addPlanting(_plantId);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _subscribeToPlant() {
    _plantSubscription = _plantRepository.watchPlantById(_plantId).listen(
      (plant) {
        _state = _state.copyWith(
          plant: plant,
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

  void _subscribeToIsPlanted() {
    _isPlantedSubscription =
        _gardenPlantingRepository.watchIsPlanted(_plantId).listen(
      (isPlanted) {
        _state = _state.copyWith(isPlanted: isPlanted);
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _plantSubscription?.cancel();
    _isPlantedSubscription?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Factory helper
// ---------------------------------------------------------------------------

/// Creates a [PlantDetailNotifier] for the plant with [plantId].
///
/// Convenience factory that resolves dependencies from [getIt].
/// Use this in [ChangeNotifierProvider.create] callbacks.
///
/// Example:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => createPlantDetailNotifier('sunflower'),
/// )
/// ```
PlantDetailNotifier createPlantDetailNotifier(
  String plantId, {
  required PlantRepository plantRepository,
  required GardenPlantingRepository gardenPlantingRepository,
}) =>
    PlantDetailNotifier(
      plantId: plantId,
      plantRepository: plantRepository,
      gardenPlantingRepository: gardenPlantingRepository,
    );
