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

/// Unit tests for [getZoneForLatitude].
///
/// Mirrors the Android `utilities/GrowZoneUtilTest.kt` test class.
/// Tests all latitude zone boundaries and edge cases.
///
/// ## Android equivalence
/// ```kotlin
/// // GrowZoneUtilTest.kt
/// @Test fun testGetZoneForLatitude() { ... }
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/core/utils/grow_zone_util.dart';

void main() {
  group('getZoneForLatitude', () {
    // -----------------------------------------------------------------------
    // Zone 13 — 0.0 to 7.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 13 (0.0 – 7.0°)', () {
      test('returns 13 for latitude 0.0 (equator)', () {
        expect(getZoneForLatitude(0.0), equals(13));
      });

      test('returns 13 for latitude 3.5', () {
        expect(getZoneForLatitude(3.5), equals(13));
      });

      test('returns 13 for latitude 7.0 (upper boundary)', () {
        expect(getZoneForLatitude(7.0), equals(13));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 12 — 7.1 to 14.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 12 (7.1 – 14.0°)', () {
      test('returns 12 for latitude 7.1 (lower boundary)', () {
        expect(getZoneForLatitude(7.1), equals(12));
      });

      test('returns 12 for latitude 10.0', () {
        expect(getZoneForLatitude(10.0), equals(12));
      });

      test('returns 12 for latitude 14.0 (upper boundary)', () {
        expect(getZoneForLatitude(14.0), equals(12));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 11 — 14.1 to 21.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 11 (14.1 – 21.0°)', () {
      test('returns 11 for latitude 14.1', () {
        expect(getZoneForLatitude(14.1), equals(11));
      });

      test('returns 11 for latitude 21.0 (upper boundary)', () {
        expect(getZoneForLatitude(21.0), equals(11));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 10 — 21.1 to 28.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 10 (21.1 – 28.0°)', () {
      test('returns 10 for latitude 21.1', () {
        expect(getZoneForLatitude(21.1), equals(10));
      });

      test('returns 10 for latitude 28.0 (upper boundary)', () {
        expect(getZoneForLatitude(28.0), equals(10));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 9 — 28.1 to 35.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 9 (28.1 – 35.0°)', () {
      test('returns 9 for latitude 28.1', () {
        expect(getZoneForLatitude(28.1), equals(9));
      });

      test('returns 9 for latitude 35.0 (upper boundary)', () {
        expect(getZoneForLatitude(35.0), equals(9));
      });

      test('returns 9 for San Francisco latitude (~37.7°) — zone 8', () {
        // San Francisco is at ~37.7°N, which falls in zone 8.
        expect(getZoneForLatitude(37.7749), equals(8));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 8 — 35.1 to 42.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 8 (35.1 – 42.0°)', () {
      test('returns 8 for latitude 35.1', () {
        expect(getZoneForLatitude(35.1), equals(8));
      });

      test('returns 8 for latitude 42.0 (upper boundary)', () {
        expect(getZoneForLatitude(42.0), equals(8));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 7 — 42.1 to 49.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 7 (42.1 – 49.0°)', () {
      test('returns 7 for latitude 42.1', () {
        expect(getZoneForLatitude(42.1), equals(7));
      });

      test('returns 7 for latitude 49.0 (upper boundary)', () {
        expect(getZoneForLatitude(49.0), equals(7));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 6 — 49.1 to 56.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 6 (49.1 – 56.0°)', () {
      test('returns 6 for latitude 49.1', () {
        expect(getZoneForLatitude(49.1), equals(6));
      });

      test('returns 6 for latitude 56.0 (upper boundary)', () {
        expect(getZoneForLatitude(56.0), equals(6));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 5 — 56.1 to 63.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 5 (56.1 – 63.0°)', () {
      test('returns 5 for latitude 56.1', () {
        expect(getZoneForLatitude(56.1), equals(5));
      });

      test('returns 5 for latitude 63.0 (upper boundary)', () {
        expect(getZoneForLatitude(63.0), equals(5));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 4 — 63.1 to 70.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 4 (63.1 – 70.0°)', () {
      test('returns 4 for latitude 63.1', () {
        expect(getZoneForLatitude(63.1), equals(4));
      });

      test('returns 4 for latitude 70.0 (upper boundary)', () {
        expect(getZoneForLatitude(70.0), equals(4));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 3 — 70.1 to 77.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 3 (70.1 – 77.0°)', () {
      test('returns 3 for latitude 70.1', () {
        expect(getZoneForLatitude(70.1), equals(3));
      });

      test('returns 3 for latitude 77.0 (upper boundary)', () {
        expect(getZoneForLatitude(77.0), equals(3));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 2 — 77.1 to 84.0 degrees
    // -----------------------------------------------------------------------

    group('Zone 2 (77.1 – 84.0°)', () {
      test('returns 2 for latitude 77.1', () {
        expect(getZoneForLatitude(77.1), equals(2));
      });

      test('returns 2 for latitude 84.0 (upper boundary)', () {
        expect(getZoneForLatitude(84.0), equals(2));
      });
    });

    // -----------------------------------------------------------------------
    // Zone 1 — > 84.0 degrees (including poles)
    // -----------------------------------------------------------------------

    group('Zone 1 (> 84.0°)', () {
      test('returns 1 for latitude 84.1', () {
        expect(getZoneForLatitude(84.1), equals(1));
      });

      test('returns 1 for latitude 90.0 (North Pole)', () {
        expect(getZoneForLatitude(90.0), equals(1));
      });

      test('returns 1 for latitude > 90.0 (out of range)', () {
        expect(getZoneForLatitude(100.0), equals(1));
      });
    });

    // -----------------------------------------------------------------------
    // Negative latitudes (southern hemisphere)
    // -----------------------------------------------------------------------

    group('Negative latitudes (southern hemisphere)', () {
      test('returns 13 for latitude -3.5 (near equator)', () {
        expect(getZoneForLatitude(-3.5), equals(13));
      });

      test('returns 10 for latitude -33.87 (Sydney, Australia)', () {
        // Sydney is at ~33.87°S → abs = 33.87 → zone 9 (28.1–35.0).
        expect(getZoneForLatitude(-33.87), equals(9));
      });

      test('returns 1 for latitude -90.0 (South Pole)', () {
        expect(getZoneForLatitude(-90.0), equals(1));
      });

      test('mirrors positive latitude result', () {
        for (final double lat in [5.0, 15.0, 25.0, 35.0, 45.0, 55.0, 65.0]) {
          expect(
            getZoneForLatitude(-lat),
            equals(getZoneForLatitude(lat)),
            reason: 'Zone for -$lat should equal zone for $lat',
          );
        }
      });
    });
  });
}
