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

/// Route path constants for the Sunflower app.
///
/// Centralises all route path strings to avoid magic strings scattered
/// throughout the codebase. Mirrors the Android `compose/Screen.kt` sealed
/// class pattern.
library;

/// Namespace for all route path constants.
///
/// Use these constants when constructing [GoRouter] routes and when
/// navigating programmatically via [GoRouter.go] / [GoRouter.push].
abstract final class RoutePaths {
  // ---------------------------------------------------------------------------
  // Root / shell
  // ---------------------------------------------------------------------------

  /// The root path. Redirects to [home].
  static const String root = '/';

  // ---------------------------------------------------------------------------
  // Home shell (bottom navigation)
  // ---------------------------------------------------------------------------

  /// The home shell path (hosts the bottom navigation bar).
  static const String home = '/home';

  // ---------------------------------------------------------------------------
  // Plant List tab
  // ---------------------------------------------------------------------------

  /// The plant list screen path (tab 0 in the bottom nav).
  static const String plantList = '/home/plant-list';

  // ---------------------------------------------------------------------------
  // Garden tab
  // ---------------------------------------------------------------------------

  /// The garden screen path (tab 1 in the bottom nav).
  static const String garden = '/home/garden';

  // ---------------------------------------------------------------------------
  // Plant Detail
  // ---------------------------------------------------------------------------

  /// The plant detail screen path.
  ///
  /// Requires a `:plantId` path parameter.
  /// Example: `/plant/apple`
  static const String plantDetail = '/plant/:plantId';

  /// Builds a concrete plant detail path for the given [plantId].
  static String plantDetailPath(String plantId) => '/plant/$plantId';

  // ---------------------------------------------------------------------------
  // Gallery
  // ---------------------------------------------------------------------------

  /// The Unsplash photo gallery screen path.
  ///
  /// Requires a `:plantName` query parameter for the search query.
  /// Example: `/gallery?plantName=Sunflower`
  static const String gallery = '/gallery';

  /// Builds a concrete gallery path for the given [plantName].
  static String galleryPath(String plantName) =>
      '/gallery?plantName=${Uri.encodeComponent(plantName)}';
}

/// Named route constants for use with [GoRouter.goNamed] / [GoRouter.pushNamed].
abstract final class RouteNames {
  /// Name for the [RoutePaths.home] route.
  static const String home = 'home';

  /// Name for the [RoutePaths.plantList] route.
  static const String plantList = 'plant-list';

  /// Name for the [RoutePaths.garden] route.
  static const String garden = 'garden';

  /// Name for the [RoutePaths.plantDetail] route.
  static const String plantDetail = 'plant-detail';

  /// Name for the [RoutePaths.gallery] route.
  static const String gallery = 'gallery';
}
