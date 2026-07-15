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

/// Unit tests for the extension methods defined in [extensions.dart].
///
/// Tests [StringExtensions], [DateTimeExtensions], [IntExtensions], and
/// [ListExtensions].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sunflower_flutter/core/utils/extensions.dart';

void main() {
  // -------------------------------------------------------------------------
  // StringExtensions
  // -------------------------------------------------------------------------

  group('StringExtensions', () {
    group('isNotBlank', () {
      test('returns true for non-empty string', () {
        expect('hello'.isNotBlank, isTrue);
      });

      test('returns true for string with content and whitespace', () {
        expect('  hello  '.isNotBlank, isTrue);
      });

      test('returns false for empty string', () {
        expect(''.isNotBlank, isFalse);
      });

      test('returns false for whitespace-only string', () {
        expect('   '.isNotBlank, isFalse);
        expect('\t\n'.isNotBlank, isFalse);
      });
    });

    group('isBlank', () {
      test('returns true for empty string', () {
        expect(''.isBlank, isTrue);
      });

      test('returns true for whitespace-only string', () {
        expect('   '.isBlank, isTrue);
      });

      test('returns false for non-empty string', () {
        expect('hello'.isBlank, isFalse);
      });
    });

    group('capitalised', () {
      test('capitalises first character and lowercases rest', () {
        expect('hello world'.capitalised, equals('Hello world'));
      });

      test('handles already-capitalised string', () {
        expect('Hello'.capitalised, equals('Hello'));
      });

      test('handles all-uppercase string', () {
        expect('HELLO'.capitalised, equals('Hello'));
      });

      test('returns empty string for empty input', () {
        expect(''.capitalised, equals(''));
      });

      test('handles single character', () {
        expect('a'.capitalised, equals('A'));
      });
    });

    group('truncate', () {
      test('truncates string longer than maxLength', () {
        expect('Hello, World!'.truncate(5), equals('Hello…'));
      });

      test('does not truncate string equal to maxLength', () {
        expect('Hello'.truncate(5), equals('Hello'));
      });

      test('does not truncate string shorter than maxLength', () {
        expect('Hi'.truncate(5), equals('Hi'));
      });

      test('uses custom ellipsis', () {
        expect('Hello, World!'.truncate(5, ellipsis: '...'), equals('Hello...'));
      });

      test('handles empty string', () {
        expect(''.truncate(5), equals(''));
      });
    });
  });

  // -------------------------------------------------------------------------
  // DateTimeExtensions
  // -------------------------------------------------------------------------

  group('DateTimeExtensions', () {
    group('addDays', () {
      test('adds positive number of days', () {
        final DateTime date = DateTime(2024, 1, 1);
        expect(date.addDays(7), equals(DateTime(2024, 1, 8)));
      });

      test('adds zero days returns same date', () {
        final DateTime date = DateTime(2024, 6, 15);
        expect(date.addDays(0), equals(date));
      });

      test('adds negative days (subtracts)', () {
        final DateTime date = DateTime(2024, 1, 10);
        expect(date.addDays(-3), equals(DateTime(2024, 1, 7)));
      });

      test('crosses month boundary correctly', () {
        final DateTime date = DateTime(2024, 1, 30);
        expect(date.addDays(5), equals(DateTime(2024, 2, 4)));
      });

      test('crosses year boundary correctly', () {
        final DateTime date = DateTime(2024, 12, 30);
        expect(date.addDays(5), equals(DateTime(2025, 1, 4)));
      });
    });

    group('isAfterDate', () {
      test('returns true when this date is after other', () {
        final DateTime later = DateTime(2024, 6, 16);
        final DateTime earlier = DateTime(2024, 6, 15);
        expect(later.isAfterDate(earlier), isTrue);
      });

      test('returns false when this date equals other (date only)', () {
        final DateTime a = DateTime(2024, 6, 15, 10, 0);
        final DateTime b = DateTime(2024, 6, 15, 20, 0);
        expect(a.isAfterDate(b), isFalse);
      });

      test('returns false when this date is before other', () {
        final DateTime earlier = DateTime(2024, 6, 14);
        final DateTime later = DateTime(2024, 6, 15);
        expect(earlier.isAfterDate(later), isFalse);
      });
    });

    group('isToday', () {
      test('returns true for DateTime.now()', () {
        expect(DateTime.now().isToday, isTrue);
      });

      test('returns false for yesterday', () {
        final DateTime yesterday =
            DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isToday, isFalse);
      });

      test('returns false for tomorrow', () {
        final DateTime tomorrow =
            DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isToday, isFalse);
      });
    });

    group('daysUntil', () {
      test('returns positive days when other is in the future', () {
        final DateTime start = DateTime(2024, 1, 1);
        final DateTime end = DateTime(2024, 1, 8);
        expect(start.daysUntil(end), equals(7));
      });

      test('returns zero when dates are the same', () {
        final DateTime date = DateTime(2024, 6, 15);
        expect(date.daysUntil(date), equals(0));
      });

      test('returns negative days when other is in the past', () {
        final DateTime start = DateTime(2024, 1, 8);
        final DateTime end = DateTime(2024, 1, 1);
        expect(start.daysUntil(end), equals(-7));
      });

      test('ignores time component', () {
        final DateTime start = DateTime(2024, 1, 1, 23, 59);
        final DateTime end = DateTime(2024, 1, 2, 0, 1);
        expect(start.daysUntil(end), equals(1));
      });
    });

    group('dateOnly', () {
      test('strips time component', () {
        final DateTime withTime = DateTime(2024, 6, 15, 14, 30, 45);
        expect(withTime.dateOnly, equals(DateTime(2024, 6, 15)));
      });

      test('returns same date when already midnight', () {
        final DateTime midnight = DateTime(2024, 6, 15);
        expect(midnight.dateOnly, equals(midnight));
      });
    });

    group('toDisplayDate', () {
      test('returns non-empty string', () {
        final DateTime date = DateTime(2024, 6, 15);
        expect(date.toDisplayDate(), isNotEmpty);
      });

      test('contains year', () {
        final DateTime date = DateTime(2024, 6, 15);
        expect(date.toDisplayDate(), contains('2024'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // IntExtensions
  // -------------------------------------------------------------------------

  group('IntExtensions', () {
    group('isValidGrowZone', () {
      test('returns true for zone 1', () {
        expect(1.isValidGrowZone, isTrue);
      });

      test('returns true for zone 13', () {
        expect(13.isValidGrowZone, isTrue);
      });

      test('returns true for zone 7', () {
        expect(7.isValidGrowZone, isTrue);
      });

      test('returns false for zone 0', () {
        expect(0.isValidGrowZone, isFalse);
      });

      test('returns false for zone 14', () {
        expect(14.isValidGrowZone, isFalse);
      });

      test('returns false for negative zone', () {
        expect((-1).isValidGrowZone, isFalse);
      });
    });

    group('clampTo', () {
      test('clamps value above max to max', () {
        expect(20.clampTo(1, 13), equals(13));
      });

      test('clamps value below min to min', () {
        expect((-5).clampTo(1, 13), equals(1));
      });

      test('returns value unchanged when within range', () {
        expect(7.clampTo(1, 13), equals(7));
      });

      test('returns min when value equals min', () {
        expect(1.clampTo(1, 13), equals(1));
      });

      test('returns max when value equals max', () {
        expect(13.clampTo(1, 13), equals(13));
      });
    });
  });

  // -------------------------------------------------------------------------
  // ListExtensions
  // -------------------------------------------------------------------------

  group('ListExtensions', () {
    group('getOrDefault', () {
      test('returns element at valid index', () {
        expect([1, 2, 3].getOrDefault(1, 0), equals(2));
      });

      test('returns default for index out of bounds (high)', () {
        expect([1, 2, 3].getOrDefault(5, 99), equals(99));
      });

      test('returns default for negative index', () {
        expect([1, 2, 3].getOrDefault(-1, 99), equals(99));
      });

      test('returns default for empty list', () {
        expect(<int>[].getOrDefault(0, 42), equals(42));
      });
    });

    group('shuffled', () {
      test('returns list with same elements', () {
        final List<int> original = [1, 2, 3, 4, 5];
        final List<int> shuffledList = original.shuffled();
        expect(shuffledList, containsAll(original));
        expect(shuffledList.length, equals(original.length));
      });

      test('does not modify original list', () {
        final List<int> original = [1, 2, 3];
        final List<int> copy = List<int>.from(original);
        original.shuffled();
        expect(original, equals(copy));
      });
    });
  });
}
