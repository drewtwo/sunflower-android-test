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

/// Application-wide constants for the Sunflower Flutter app.
///
/// Ported from the Android `utilities/Constants.kt` and extended with
/// Flutter-specific configuration such as API endpoints, pagination
/// defaults, and environment-variable keys.
library;

/// The name of the local SQLite database file.
///
/// Mirrors `DATABASE_NAME` in the Android `utilities/Constants.kt`.
const String databaseName = 'sunflower-db';

/// The asset path for the bundled plant seed data.
///
/// Mirrors `PLANT_DATA_FILENAME` in the Android `utilities/Constants.kt`.
const String plantDataFilename = 'assets/plants.json';

// ---------------------------------------------------------------------------
// Unsplash API
// ---------------------------------------------------------------------------

/// The base URL for the Unsplash REST API.
const String unsplashBaseUrl = 'https://api.unsplash.com/';

/// The Unsplash search-photos endpoint path.
const String unsplashSearchPhotosPath = 'search/photos';

/// The `--dart-define` key used to inject the Unsplash access key at
/// build time.
///
/// Usage:
/// ```
/// flutter run --dart-define=UNSPLASH_ACCESS_KEY=your_key_here
/// ```
const String unsplashAccessKeyEnvVar = 'UNSPLASH_ACCESS_KEY';

/// The Unsplash access key, injected via `--dart-define` at build time.
///
/// Falls back to an empty string if the key is not provided, which will
/// cause Unsplash API calls to fail gracefully with a 401 response.
const String unsplashAccessKey = String.fromEnvironment(
  unsplashAccessKeyEnvVar,
  defaultValue: '',
);

/// The default number of photos to request per page from the Unsplash API.
const int unsplashPageSize = 25;

/// The maximum number of pages to fetch from the Unsplash API.
const int unsplashMaxPages = 500;

// ---------------------------------------------------------------------------
// HTTP client
// ---------------------------------------------------------------------------

/// Default connection timeout for the Dio HTTP client.
const Duration httpConnectTimeout = Duration(seconds: 15);

/// Default receive timeout for the Dio HTTP client.
const Duration httpReceiveTimeout = Duration(seconds: 30);

/// Default send timeout for the Dio HTTP client.
const Duration httpSendTimeout = Duration(seconds: 15);

// ---------------------------------------------------------------------------
// Grow zone
// ---------------------------------------------------------------------------

/// The number of USDA hardiness zones supported by [getZoneForLatitude].
const int growZoneCount = 13;

/// Sentinel value indicating that no grow-zone filter is active.
const int noFilterGrowZone = -1;

// ---------------------------------------------------------------------------
// UI / layout
// ---------------------------------------------------------------------------

/// Standard horizontal padding used throughout the app.
const double horizontalPadding = 12.0;

/// Standard vertical padding used throughout the app.
const double verticalPadding = 12.0;

/// The number of columns in the plant-list grid on a compact screen.
const int plantListGridColumnsCompact = 2;

/// The number of columns in the plant-list grid on a medium/expanded screen.
const int plantListGridColumnsMedium = 3;

/// The height of the plant card image.
const double plantCardImageHeight = 95.0;

/// The corner radius used for plant card images.
const double plantCardImageCornerRadius = 12.0;
