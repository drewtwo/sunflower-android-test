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

/// Mock repository implementations for use in unit tests.
///
/// Uses [mocktail] to create mock classes that can be configured with
/// `when(...)` and verified with `verify(...)`.
///
/// Mirrors the Android test pattern of using Mockito to mock repositories
/// in ViewModel tests.
///
/// ## Usage
/// ```dart
/// import 'package:sunflower_flutter/test/mocks/mock_repositories.dart';
///
/// void main() {
///   late MockPlantRepository mockPlantRepo;
///
///   setUp(() {
///     mockPlantRepo = MockPlantRepository();
///     when(() => mockPlantRepo.watchAllPlants())
///         .thenAnswer((_) => Stream.value([...plants]));
///   });
/// }
/// ```
library;

import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/app_database.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';
import 'package:sunflower_flutter/data/models/plant.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';
import 'package:sunflower_flutter/data/repositories/garden_planting_repository.dart';
import 'package:sunflower_flutter/data/repositories/plant_repository.dart';
import 'package:sunflower_flutter/data/repositories/unsplash_repository.dart';

// ---------------------------------------------------------------------------
// Mock repositories
// ---------------------------------------------------------------------------

/// Mock implementation of [PlantRepository].
///
/// Use with [mocktail]:
/// ```dart
/// final mock = MockPlantRepository();
/// when(() => mock.watchAllPlants()).thenAnswer((_) => Stream.value(plants));
/// ```
class MockPlantRepository extends Mock implements PlantRepository {}

/// Mock implementation of [GardenPlantingRepository].
///
/// Use with [mocktail]:
/// ```dart
/// final mock = MockGardenPlantingRepository();
/// when(() => mock.watchGardenPlantings()).thenAnswer((_) => Stream.value([]));
/// ```
class MockGardenPlantingRepository extends Mock
    implements GardenPlantingRepository {}

/// Mock implementation of [UnsplashRepository].
///
/// Use with [mocktail]:
/// ```dart
/// final mock = MockUnsplashRepository();
/// when(() => mock.searchPhotos(query: any(named: 'query'), page: any(named: 'page')))
///     .thenAnswer((_) async => UnsplashPageResult(...));
/// ```
class MockUnsplashRepository extends Mock implements UnsplashRepository {}

// ---------------------------------------------------------------------------
// Mock DAOs
// ---------------------------------------------------------------------------

/// Mock implementation of [PlantDao].
class MockPlantDao extends Mock implements PlantDao {}

/// Mock implementation of [GardenPlantingDao].
class MockGardenPlantingDao extends Mock implements GardenPlantingDao {}

// ---------------------------------------------------------------------------
// Mock HTTP client
// ---------------------------------------------------------------------------

/// Mock implementation of [UnsplashClient].
///
/// Use with [mocktail]:
/// ```dart
/// final mock = MockUnsplashClient();
/// when(() => mock.searchPhotos(query: 'sunflower', page: 1))
///     .thenAnswer((_) async => UnsplashSearchResponse(...));
/// ```
class MockUnsplashClient extends Mock implements UnsplashClient {}

// ---------------------------------------------------------------------------
// Fallback values registration
// ---------------------------------------------------------------------------

/// Registers fallback values for [mocktail] matchers.
///
/// Call this in `setUpAll` before using any `any()` matchers with
/// custom types.
///
/// Example:
/// ```dart
/// setUpAll(registerFallbackValues);
/// ```
void registerFallbackValues() {
  registerFallbackValue(
    const UnsplashSearchResponse(results: [], totalPages: 0),
  );
}
