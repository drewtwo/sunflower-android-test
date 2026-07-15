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

/// Provider-based state management for the plant list feature.
///
/// Mirrors the Android `PlantListViewModel` defined in
/// `viewmodels/PlantListViewModel.kt`.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@HiltViewModel`                  | `ChangeNotifier` + `ChangeNotifierProvider` |
/// | `MutableStateFlow<Int> growZone`  | `int _growZone` field               |
/// | `LiveData<List<Plant>> plants`    | `Stream<List<Plant>>` via repository |
/// | `fun setGrowZoneNumber(num: Int)` | `setGrowZone(int zone)`             |
/// | `fun clearGrowZoneNumber()`       | `clearGrowZone()`                   |
/// | `fun isFiltered()`                | `bool get isFiltered`               |
/// | `savedStateHandle`                | (not needed — Provider handles it)  |
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Represents the state of the plant list screen.
///
/// Mirrors the combination of `growZone: MutableStateFlow<Int>` and
/// `plants: LiveData<List<Plant>>` in the Android ViewModel.
class PlantListState {
  /// Creates a [PlantListState].
  const PlantListState({
    this.plants = const [],
    this.isLoading = false,
    this.errorMessage,
    this.growZone = noFilterGrowZone,
  });

  /// The list of plants to display.
  final List<Plant> plants;

  /// Whether the plant list is currently loading.
  final bool isLoading;

  /// An error message, or `null` if there is no error.
  final String? errorMessage;

  /// The currently active grow zone filter, or [noFilterGrowZone] if unfiltered.
  final int growZone;

  /// Returns `true` if a grow zone filter is currently active.
  bool get isFiltered => growZone != noFilterGrowZone;

  /// Returns a copy of this state with the given fields replaced.
  PlantListState copyWith({
    List<Plant>? plants,
    bool? isLoading,
    String? errorMessage,
    int? growZone,
    bool clearError = false,
  }) =>
      PlantListState(
        plants: plants ?? this.plants,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        growZone: growZone ?? this.growZone,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for the plant list screen.
///
/// Mirrors the Android `PlantListViewModel` class. Uses [ChangeNotifier]
/// instead of Android's `ViewModel` + `LiveData` pattern.
///
/// ## Usage
/// ```dart
/// // In a widget:
/// final notifier = context.watch<PlantListNotifier>();
/// final plants = notifier.state.plants;
/// notifier.setGrowZone(9);
/// ```
class PlantListNotifier extends ChangeNotifier {
  /// Creates a [PlantListNotifier] with the given [_repository].
  ///
  /// Immediately subscribes to the plant stream and starts loading data.
  PlantListNotifier(this._repository) {
    _subscribeToPlants();
  }

  final PlantRepository _repository;

  PlantListState _state = const PlantListState(isLoading: true);
  StreamSubscription<List<Plant>>? _plantsSubscription;

  /// The current state of the plant list.
  PlantListState get state => _state;

  // ---------------------------------------------------------------------------
  // Public API — mirrors PlantListViewModel methods
  // ---------------------------------------------------------------------------

  /// Sets the grow zone filter to [zone].
  ///
  /// Mirrors `fun setGrowZoneNumber(num: Int)`.
  void setGrowZone(int zone) {
    if (_state.growZone == zone) return;
    _state = _state.copyWith(growZone: zone, isLoading: true);
    notifyListeners();
    _subscribeToPlants();
  }

  /// Clears the grow zone filter, showing all plants.
  ///
  /// Mirrors `fun clearGrowZoneNumber()`.
  void clearGrowZone() {
    if (!_state.isFiltered) return;
    _state = _state.copyWith(growZone: noFilterGrowZone, isLoading: true);
    notifyListeners();
    _subscribeToPlants();
  }

  /// Toggles the grow zone filter.
  ///
  /// If filtered, clears the filter. If unfiltered, sets zone to 9.
  /// Mirrors `fun updateData()` in the Android ViewModel.
  void toggleFilter() {
    if (_state.isFiltered) {
      clearGrowZone();
    } else {
      setGrowZone(9);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Subscribes to the appropriate plant stream based on the current grow zone.
  ///
  /// Mirrors the `growZone.flatMapLatest { zone -> ... }` pattern in the
  /// Android ViewModel.
  void _subscribeToPlants() {
    _plantsSubscription?.cancel();

    final Stream<List<Plant>> stream = _state.isFiltered
        ? _repository.watchPlantsWithGrowZone(_state.growZone)
        : _repository.watchAllPlants();

    _plantsSubscription = stream.listen(
      (plants) {
        _state = _state.copyWith(
          plants: plants,
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
    _plantsSubscription?.cancel();
    super.dispose();
  }
}
