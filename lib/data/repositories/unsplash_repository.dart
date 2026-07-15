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

/// Repository for Unsplash photo search results.
///
/// Mirrors the Android `data/UnsplashRepository.kt` class. Provides paginated
/// photo search results using the [infinite_scroll_pagination] package
/// (equivalent to Android's Paging 3 library).
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `Pager(config, pagingSourceFactory)` | `PagingController` (in provider) |
/// | `PagingConfig(pageSize = 25)`     | `networkPageSize = 25`              |
/// | `UnsplashPagingSource`            | `_fetchPage()` callback             |
/// | `Flow<PagingData<UnsplashPhoto>>` | `PagingController<int, UnsplashPhoto>` |
///
/// ## Usage
/// ```dart
/// final repo = getIt<UnsplashRepository>();
/// final result = await repo.searchPhotos(query: 'sunflower', page: 1);
/// ```
library;

import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';
import 'package:sunflower_flutter/data/models/unsplash_photo.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';

/// The number of photos to request per page from the Unsplash API.
///
/// Mirrors `private const val NETWORK_PAGE_SIZE = 25` in the Android
/// `UnsplashRepository`.
const int networkPageSize = unsplashPageSize;

/// Result of a single page fetch from the Unsplash API.
///
/// Encapsulates the photos for the current page and pagination metadata.
class UnsplashPageResult {
  /// Creates an [UnsplashPageResult].
  const UnsplashPageResult({
    required this.photos,
    required this.currentPage,
    required this.totalPages,
    required this.query,
  });

  /// The photos returned for this page.
  final List<UnsplashPhoto> photos;

  /// The current page number (1-based).
  final int currentPage;

  /// The total number of pages available for this query.
  final int totalPages;

  /// The search query that produced these results.
  final String query;

  /// Returns `true` if there are more pages to load.
  bool get hasNextPage => currentPage < totalPages;

  /// Returns the next page number, or `null` if this is the last page.
  int? get nextPage => hasNextPage ? currentPage + 1 : null;
}

/// Repository for Unsplash photo search results.
///
/// This class is registered as a singleton in [ServiceLocator] and should
/// be accessed via `getIt<UnsplashRepository>()`.
class UnsplashRepository {
  /// Creates an [UnsplashRepository] with the given [_client].
  const UnsplashRepository(this._client);

  final UnsplashClient _client;

  /// Fetches a single page of photo search results for [query].
  ///
  /// [page] is 1-based. [perPage] defaults to [networkPageSize].
  ///
  /// Returns an [UnsplashPageResult] containing the photos and pagination
  /// metadata needed to implement infinite scrolling.
  ///
  /// Throws [UnsplashApiException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity failures.
  ///
  /// Mirrors the `UnsplashPagingSource.load()` method in the Android
  /// implementation, which is called by the Paging 3 library.
  Future<UnsplashPageResult> searchPhotos({
    required String query,
    required int page,
    int perPage = networkPageSize,
  }) async {
    final UnsplashSearchResponse response = await _client.searchPhotos(
      query: query,
      page: page,
      perPage: perPage,
    );

    return UnsplashPageResult(
      photos: response.results,
      currentPage: page,
      totalPages: response.totalPages,
      query: query,
    );
  }

  /// Returns the first page of results for [query].
  ///
  /// Convenience method for initial loads. For subsequent pages, use
  /// [searchPhotos] with the appropriate page number.
  Future<UnsplashPageResult> getInitialSearchResults(String query) =>
      searchPhotos(query: query, page: 1);
}
