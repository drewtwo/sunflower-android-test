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

/// DateTime type converters for drift database storage.
///
/// Mirrors the Android Room `Converters.kt` class which provides
/// `@TypeConverter` methods for converting between `Calendar` and `Long`
/// (Unix timestamp in milliseconds).
///
/// In drift, [DateTime] columns are natively supported and stored as Unix
/// timestamps (milliseconds since epoch) by default. This file provides
/// additional utility functions for manual conversion when needed outside
/// of drift's automatic handling.
///
/// ## Android → Dart mapping
/// | Android (Room Converters.kt)      | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@TypeConverter calendarToDatestamp(Calendar)` | `dateTimeToTimestamp(DateTime)` |
/// | `@TypeConverter datestampToCalendar(Long)`     | `timestampToDateTime(int)`      |
library;

/// Converts a [DateTime] to a Unix timestamp (milliseconds since epoch).
///
/// Mirrors the Android `Converters.calendarToDatestamp(Calendar): Long`
/// type converter. Drift handles this automatically for [DateTimeColumn],
/// but this function is useful for manual serialization.
///
/// Returns `null` if [dateTime] is `null`.
///
/// Example:
/// ```dart
/// final timestamp = dateTimeToTimestamp(DateTime(2024, 1, 1));
/// // → 1704067200000
/// ```
int? dateTimeToTimestamp(DateTime? dateTime) =>
    dateTime?.millisecondsSinceEpoch;

/// Converts a Unix timestamp (milliseconds since epoch) to a [DateTime].
///
/// Mirrors the Android `Converters.datestampToCalendar(Long): Calendar`
/// type converter.
///
/// Returns `null` if [timestamp] is `null`.
///
/// Example:
/// ```dart
/// final dateTime = timestampToDateTime(1704067200000);
/// // → DateTime(2024, 1, 1, 0, 0, 0, 0, 0) UTC
/// ```
DateTime? timestampToDateTime(int? timestamp) => timestamp == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(timestamp);

/// Converts a [DateTime] to a Unix timestamp (milliseconds since epoch).
///
/// Non-nullable version of [dateTimeToTimestamp].
int dateTimeToTimestampNonNull(DateTime dateTime) =>
    dateTime.millisecondsSinceEpoch;

/// Converts a Unix timestamp (milliseconds since epoch) to a [DateTime].
///
/// Non-nullable version of [timestampToDateTime].
DateTime timestampToDateTimeNonNull(int timestamp) =>
    DateTime.fromMillisecondsSinceEpoch(timestamp);

/// A drift-compatible type converter for [DateTime] ↔ [int] (Unix ms).
///
/// This can be used with drift's `TypeConverter` API if you need to store
/// [DateTime] values in an [IntColumn] rather than drift's native
/// [DateTimeColumn].
///
/// ## Usage with drift
/// ```dart
/// // In a drift table definition:
/// IntColumn get plantDate =>
///   integer().map(const DateTimeConverter())();
/// ```
class DateTimeConverter {
  /// Creates a [DateTimeConverter].
  const DateTimeConverter();

  /// Converts a [DateTime] to a Unix timestamp for storage.
  int toSql(DateTime value) => value.millisecondsSinceEpoch;

  /// Converts a Unix timestamp from storage to a [DateTime].
  DateTime fromSql(int fromDb) => DateTime.fromMillisecondsSinceEpoch(fromDb);
}
