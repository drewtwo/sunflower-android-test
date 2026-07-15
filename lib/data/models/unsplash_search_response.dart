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

/// Data transfer object for the Unsplash photo search response.
///
/// Mirrors the Android `data/UnsplashSearchResponse.kt` data class.
/// Uses [json_serializable] for JSON deserialization.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:sunflower_flutter/data/models/unsplash_photo.dart';

part 'unsplash_search_response.g.dart';

/// Represents the top-level response from the Unsplash search-photos endpoint.
///
/// Not all fields returned from the API are represented here; only those used
/// in this project are listed. For a full list of fields, consult the API
/// documentation: https://unsplash.com/documentation#search-photos
@JsonSerializable(createToJson: false)
class UnsplashSearchResponse {
  /// Creates an [UnsplashSearchResponse] instance.
  const UnsplashSearchResponse({
    required this.results,
    required this.totalPages,
  });

  /// Deserializes an [UnsplashSearchResponse] from a JSON map.
  factory UnsplashSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$UnsplashSearchResponseFromJson(json);

  /// The list of [UnsplashPhoto] results for the current page.
  final List<UnsplashPhoto> results;

  /// The total number of pages available for this query.
  @JsonKey(name: 'total_pages')
  final int totalPages;
}
