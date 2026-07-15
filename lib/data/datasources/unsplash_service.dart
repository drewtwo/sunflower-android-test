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

/// Unsplash API service layer.
///
/// This file provides the [UnsplashService] class, a thin wrapper around
/// [UnsplashClient] that adds request/response logging and error handling.
///
/// In the Android implementation, the Retrofit `UnsplashService` interface
/// (`api/UnsplashService.kt`) is automatically implemented by Retrofit.
/// In Flutter, we implement the service manually using dio.
///
/// ## Relationship to other classes
/// - [UnsplashClient] — low-level HTTP client (dio wrapper)
/// - [UnsplashService] — service layer with logging and error handling
/// - [UnsplashRepository] — repository layer with pagination support
library;

import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';

/// Service class for the Unsplash REST API.
///
/// Wraps [UnsplashClient] with additional logging and error handling.
/// Mirrors the Android `UnsplashService` Retrofit interface defined in
/// `api/UnsplashService.kt`.
///
/// This class is registered as a singleton in [ServiceLocator] and should
/// be accessed via `getIt<UnsplashService>()`.
class UnsplashService {
  /// Creates an [UnsplashService] with the given [_client].
  const UnsplashService(this._client);

  final UnsplashClient _client;

  /// Searches for photos matching [query] on the given [page].
  ///
  /// [perPage] defaults to [unsplashPageSize] (25).
  ///
  /// Mirrors the Android Retrofit method:
  /// ```kotlin
  /// @GET("search/photos")
  /// suspend fun searchPhotos(
  ///   @Query("query") query: String,
  ///   @Query("page") page: Int,
  ///   @Query("per_page") perPage: Int,
  ///   @Query("client_id") clientId: String
  /// ): UnsplashSearchResponse
  /// ```
  ///
  /// Throws [UnsplashApiException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity failures.
  Future<UnsplashSearchResponse> searchPhotos({
    required String query,
    required int page,
    int perPage = unsplashPageSize,
  }) async {
    // ignore: avoid_print — intentional request logging
    print('[UnsplashService] searchPhotos: query=$query, page=$page, perPage=$perPage');

    try {
      final response = await _client.searchPhotos(
        query: query,
        page: page,
        perPage: perPage,
      );

      // ignore: avoid_print — intentional response logging
      print('[UnsplashService] searchPhotos: received ${response.results.length} results, '
          'totalPages=${response.totalPages}');

      return response;
    } on UnsplashApiException catch (e) {
      // ignore: avoid_print — intentional error logging
      print('[UnsplashService] API error: $e');
      rethrow;
    } on NetworkException catch (e) {
      // ignore: avoid_print — intentional error logging
      print('[UnsplashService] Network error: $e');
      rethrow;
    }
  }
}
