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

/// Data transfer objects for the Unsplash API.
///
/// This file consolidates three Android files into one:
/// - `data/UnsplashPhoto.kt`     → [UnsplashPhoto]
/// - `data/UnsplashPhotoUrls.kt` → [UnsplashPhotoUrls]
/// - `data/UnsplashUser.kt`      → [UnsplashUser]
///
/// Uses [json_serializable] for JSON deserialization, replacing Android's
/// Gson `@SerializedName` annotations. The `@JsonKey(name: ...)` annotation
/// is used where the JSON field name differs from the Dart field name.
///
/// ## Code generation
/// Run `flutter pub run build_runner build --delete-conflicting-outputs`
/// to regenerate `unsplash_photo.g.dart`.
library;

import 'package:json_annotation/json_annotation.dart';

part 'unsplash_photo.g.dart';

// ---------------------------------------------------------------------------
// UnsplashPhotoUrls
// ---------------------------------------------------------------------------

/// The set of image URLs returned for a single Unsplash photo.
///
/// Mirrors `data/UnsplashPhotoUrls.kt`:
/// ```kotlin
/// data class UnsplashPhotoUrls(val raw: String, val full: String,
///   val regular: String, val small: String, val thumb: String)
/// ```
@JsonSerializable(createToJson: false)
class UnsplashPhotoUrls {
  /// Creates an [UnsplashPhotoUrls] instance.
  const UnsplashPhotoUrls({
    required this.raw,
    required this.full,
    required this.regular,
    required this.small,
    required this.thumb,
  });

  /// Deserializes an [UnsplashPhotoUrls] from a JSON map.
  factory UnsplashPhotoUrls.fromJson(Map<String, dynamic> json) =>
      _$UnsplashPhotoUrlsFromJson(json);

  /// The raw (full-resolution) image URL.
  final String raw;

  /// The full-size image URL.
  final String full;

  /// A regular-size image URL (suitable for most display contexts).
  final String regular;

  /// A small image URL.
  final String small;

  /// A thumbnail image URL.
  final String thumb;
}

// ---------------------------------------------------------------------------
// UnsplashUser
// ---------------------------------------------------------------------------

/// Represents the photographer who uploaded the photo.
///
/// Mirrors `data/UnsplashUser.kt`:
/// ```kotlin
/// data class UnsplashUser(val name: String, val username: String) {
///   val attributionUrl get() = "https://unsplash.com/$username?..."
/// }
/// ```
@JsonSerializable(createToJson: false)
class UnsplashUser {
  /// Creates an [UnsplashUser] instance.
  const UnsplashUser({
    required this.name,
    required this.username,
  });

  /// Deserializes an [UnsplashUser] from a JSON map.
  factory UnsplashUser.fromJson(Map<String, dynamic> json) =>
      _$UnsplashUserFromJson(json);

  /// The photographer's display name.
  final String name;

  /// The photographer's Unsplash username (used to build attribution URLs).
  final String username;

  /// The Unsplash attribution URL for this photographer.
  ///
  /// Mirrors `val attributionUrl get() = "https://unsplash.com/$username?..."`.
  /// The UTM parameters are required by the Unsplash API guidelines.
  String get attributionUrl =>
      'https://unsplash.com/$username?utm_source=sunflower&utm_medium=referral';
}

// ---------------------------------------------------------------------------
// UnsplashPhoto
// ---------------------------------------------------------------------------

/// Represents a single photo returned by the Unsplash API.
///
/// Mirrors `data/UnsplashPhoto.kt`. Not all API fields are represented here;
/// only those used in this project are listed. For a full list of fields,
/// consult the Unsplash API documentation:
/// https://unsplash.com/documentation#get-a-photo
///
/// ## Android → Dart mapping
/// | Android (Gson)                    | Dart (json_serializable)            |
/// |-----------------------------------|-------------------------------------|
/// | `@SerializedName("id")`           | field name matches JSON key          |
/// | `@SerializedName("urls")`         | field name matches JSON key          |
/// | `@SerializedName("user")`         | field name matches JSON key          |
@JsonSerializable(createToJson: false)
class UnsplashPhoto {
  /// Creates an [UnsplashPhoto] instance.
  const UnsplashPhoto({
    required this.id,
    required this.urls,
    required this.user,
  });

  /// Deserializes an [UnsplashPhoto] from a JSON map.
  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) =>
      _$UnsplashPhotoFromJson(json);

  /// The unique identifier for this photo.
  final String id;

  /// The set of image URLs for this photo.
  final UnsplashPhotoUrls urls;

  /// The photographer who uploaded this photo.
  final UnsplashUser user;
}
