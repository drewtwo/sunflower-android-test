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

/// USDA Plant Hardiness Zone helper.
///
/// Ported from the Android Sunflower `utilities/GrowZoneUtil.kt`.
///
/// The numbers listed here are roughly based on the United States Department
/// of Agriculture's Plant Hardiness Zone Map
/// (http://planthardiness.ars.usda.gov/), which helps determine which plants
/// are most likely to thrive at a location.
///
/// If a given latitude falls on the border between two zone ranges, the
/// larger zone range is chosen (e.g. latitude 14.0 → zone 12).
///
/// Negative latitude values are converted to positive with [latitude.abs()].
///
/// For latitude values greater than the maximum (90.0), zone 1 is returned.
///
/// ## Zone boundaries
/// | Latitude range | Zone |
/// |----------------|------|
/// | 0.0 – 7.0      | 13   |
/// | 7.1 – 14.0     | 12   |
/// | 14.1 – 21.0    | 11   |
/// | 21.1 – 28.0    | 10   |
/// | 28.1 – 35.0    | 9    |
/// | 35.1 – 42.0    | 8    |
/// | 42.1 – 49.0    | 7    |
/// | 49.1 – 56.0    | 6    |
/// | 56.1 – 63.0    | 5    |
/// | 63.1 – 70.0    | 4    |
/// | 70.1 – 77.0    | 3    |
/// | 77.1 – 84.0    | 2    |
/// | > 84.0         | 1    |
library;

/// Returns the USDA hardiness zone number for the given [latitude].
///
/// [latitude] may be negative (southern hemisphere); the absolute value is
/// used for the zone calculation.
///
/// Returns an integer in the range [1, 13].
///
/// Example:
/// ```dart
/// final zone = getZoneForLatitude(37.7749); // San Francisco → 9
/// final zone2 = getZoneForLatitude(-33.8688); // Sydney → 10
/// ```
int getZoneForLatitude(double latitude) {
  final double absLat = latitude.abs();

  if (absLat <= 7.0) return 13;
  if (absLat <= 14.0) return 12;
  if (absLat <= 21.0) return 11;
  if (absLat <= 28.0) return 10;
  if (absLat <= 35.0) return 9;
  if (absLat <= 42.0) return 8;
  if (absLat <= 49.0) return 7;
  if (absLat <= 56.0) return 6;
  if (absLat <= 63.0) return 5;
  if (absLat <= 70.0) return 4;
  if (absLat <= 77.0) return 3;
  if (absLat <= 84.0) return 2;

  // Remaining latitudes (> 84.0, including > 90.0) are assigned to zone 1.
  return 1;
}
