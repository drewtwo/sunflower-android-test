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

/// Dart extension methods used throughout the Sunflower app.
///
/// Provides convenience helpers on [String], [DateTime], and [int] that
/// replace common utility patterns from the Android Kotlin codebase.
library;

import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// String extensions
// ---------------------------------------------------------------------------

/// Extensions on [String] for common formatting and validation helpers.
extension StringExtensions on String {
  /// Returns `true` if this string is not empty after trimming whitespace.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns `true` if this string is empty or contains only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Capitalises the first character of this string and lowercases the rest.
  ///
  /// Returns an empty string if this string is empty.
  String get capitalised {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Truncates this string to [maxLength] characters, appending [ellipsis]
  /// if the string was truncated.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}

// ---------------------------------------------------------------------------
// DateTime extensions
// ---------------------------------------------------------------------------

/// Extensions on [DateTime] for display formatting and watering logic.
extension DateTimeExtensions on DateTime {
  /// Formats this [DateTime] as a human-readable date string using the
  /// device locale.
  ///
  /// Example: `"Jun 15, 2024"`
  String toDisplayDate() => DateFormat.yMMMd().format(this);

  /// Returns `true` if this [DateTime] is strictly after [other] when
  /// comparing only the date portion (year, month, day).
  bool isAfterDate(DateTime other) {
    final DateTime thisDate = DateTime(year, month, day);
    final DateTime otherDate = DateTime(other.year, other.month, other.day);
    return thisDate.isAfter(otherDate);
  }

  /// Returns a new [DateTime] with [days] added to this instance.
  ///
  /// Equivalent to `Calendar.add(DAY_OF_YEAR, days)` in the Android
  /// implementation.
  DateTime addDays(int days) => add(Duration(days: days));

  /// Returns `true` if this [DateTime] represents today's date.
  bool get isToday {
    final DateTime now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns the number of whole days between this [DateTime] and [other].
  ///
  /// The result is positive if [other] is in the future relative to this.
  int daysUntil(DateTime other) =>
      DateTime(other.year, other.month, other.day)
          .difference(DateTime(year, month, day))
          .inDays;
}

// ---------------------------------------------------------------------------
// int extensions
// ---------------------------------------------------------------------------

/// Extensions on [int] for grow-zone and UI helpers.
extension IntExtensions on int {
  /// Returns `true` if this integer represents a valid USDA grow zone
  /// (i.e. in the range [1, 13]).
  bool get isValidGrowZone => this >= 1 && this <= 13;

  /// Clamps this integer to the range [[min], [max]] (inclusive).
  int clampTo(int min, int max) => clamp(min, max).toInt();
}

// ---------------------------------------------------------------------------
// List extensions
// ---------------------------------------------------------------------------

/// Extensions on [List] for common collection helpers.
extension ListExtensions<T> on List<T> {
  /// Returns a new list with the elements of this list shuffled.
  List<T> shuffled() => List<T>.from(this)..shuffle();

  /// Returns the element at [index], or [defaultValue] if [index] is out
  /// of bounds.
  T getOrDefault(int index, T defaultValue) =>
      (index >= 0 && index < length) ? this[index] : defaultValue;
}
