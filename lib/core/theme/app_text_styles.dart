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

/// Typography scale for the Sunflower app.
///
/// Ported from the Android Sunflower `ui/Type.kt` file.
/// Uses [TextStyle] values that mirror the Material 3 typography roles
/// defined in the original Compose implementation.
library;

import 'package:flutter/material.dart';

/// The full [TextTheme] used by [SunflowerTheme].
///
/// Mirrors the `Typography` object defined in the Android `ui/Type.kt`.
const TextTheme sunflowerTextTheme = TextTheme(
  /// Equivalent to `displaySmall` in the Android implementation.
  displaySmall: TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 36,
  ),

  /// Equivalent to `headlineSmall` in the Android implementation.
  headlineSmall: TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 30,
  ),

  /// Equivalent to `labelSmall` in the Android implementation.
  labelSmall: TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
  ),

  /// Equivalent to `titleSmall` in the Android implementation.
  titleSmall: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  ),

  /// Equivalent to `titleMedium` in the Android implementation.
  titleMedium: TextStyle(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontSize: 18,
  ),

  /// Equivalent to `titleLarge` in the Android implementation.
  titleLarge: TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 24,
  ),
);
