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

/// Dio HTTP client configuration for the Unsplash API.
///
/// Mirrors the Android `api/UnsplashService.kt` and the Retrofit/OkHttp
/// setup in `di/NetworkModule.kt`. Provides a pre-configured [Dio] instance
/// with:
/// - Base URL pointing to the Unsplash API.
/// - Logging interceptor (debug builds only).
/// - Error-handling interceptor that maps HTTP errors to typed exceptions.
/// - Timeout configuration from [AppConstants].
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | Retrofit `@GET("search/photos")`  | `dio.get(unsplashSearchPhotosPath)` |
/// | OkHttp `HttpLoggingInterceptor`   | dio `LogInterceptor`                |
/// | Hilt `@Provides @Singleton Retrofit` | `createUnsplashDio()` singleton  |
/// | `@Query("query")` parameter       | `queryParameters: {'query': ...}`   |
library;

import 'package:dio/dio.dart';
import 'package:sunflower_flutter/core/constants/app_constants.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';

// ---------------------------------------------------------------------------
// Typed exceptions
// ---------------------------------------------------------------------------

/// Thrown when the Unsplash API returns a non-2xx HTTP response.
///
/// Mirrors the HTTP error handling that Retrofit provides automatically
/// in the Android implementation.
class UnsplashApiException implements Exception {
  /// Creates an [UnsplashApiException].
  const UnsplashApiException({
    required this.statusCode,
    required this.message,
  });

  /// The HTTP status code returned by the API.
  final int statusCode;

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() => 'UnsplashApiException($statusCode): $message';
}

/// Thrown when a network request fails due to connectivity issues.
class NetworkException implements Exception {
  /// Creates a [NetworkException].
  const NetworkException(this.message);

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

// ---------------------------------------------------------------------------
// Interceptors
// ---------------------------------------------------------------------------

/// A Dio interceptor that converts [DioException]s into typed exceptions.
///
/// Mirrors the error handling that Retrofit + OkHttp provide in the Android
/// implementation, where HTTP errors are automatically converted to
/// `HttpException` instances.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.badResponse:
        final int statusCode = err.response?.statusCode ?? 0;
        final String message =
            err.response?.statusMessage ?? 'Unknown API error';
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: UnsplashApiException(
              statusCode: statusCode,
              message: message,
            ),
          ),
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(err.message ?? 'Network error'),
          ),
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        handler.next(err);
    }
  }
}

// ---------------------------------------------------------------------------
// Client factory
// ---------------------------------------------------------------------------

/// Creates and returns a pre-configured [Dio] instance for the Unsplash API.
///
/// The returned instance has:
/// - [unsplashBaseUrl] as the base URL.
/// - Connection, receive, and send timeouts from [AppConstants].
/// - A [LogInterceptor] for request/response logging.
/// - An [_ErrorInterceptor] for typed error handling.
///
/// Mirrors the Hilt `@Provides @Singleton` method in `NetworkModule.kt`
/// that creates the Retrofit instance.
///
/// Example:
/// ```dart
/// final dio = createUnsplashDio();
/// final client = UnsplashClient(dio);
/// ```
Dio createUnsplashDio() {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: unsplashBaseUrl,
      connectTimeout: httpConnectTimeout,
      receiveTimeout: httpReceiveTimeout,
      sendTimeout: httpSendTimeout,
      headers: <String, String>{
        'Accept-Version': 'v1',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Logging interceptor — mirrors OkHttp HttpLoggingInterceptor(Level.BASIC).
  // Logs request URL and response status code for debugging.
  dio.interceptors.add(
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
      // ignore: avoid_print — intentional debug logging
      logPrint: (Object message) => print('[Unsplash] $message'),
    ),
  );

  // Error-handling interceptor — converts DioExceptions to typed exceptions.
  dio.interceptors.add(_ErrorInterceptor());

  return dio;
}

// ---------------------------------------------------------------------------
// Unsplash API client
// ---------------------------------------------------------------------------

/// A typed HTTP client for the Unsplash REST API.
///
/// Mirrors the Android `UnsplashService` Retrofit interface defined in
/// `api/UnsplashService.kt`. All methods are `async` and return deserialized
/// Dart objects.
///
/// ## Android → Dart mapping
/// ```kotlin
/// // Android (Retrofit)
/// @GET("search/photos")
/// suspend fun searchPhotos(
///   @Query("query") query: String,
///   @Query("page") page: Int,
///   @Query("per_page") perPage: Int,
///   @Query("client_id") clientId: String
/// ): UnsplashSearchResponse
/// ```
/// ```dart
/// // Dart (dio)
/// Future<UnsplashSearchResponse> searchPhotos({...}) async {
///   final response = await _dio.get(unsplashSearchPhotosPath, queryParameters: {...});
///   return UnsplashSearchResponse.fromJson(response.data);
/// }
/// ```
class UnsplashClient {
  /// Creates an [UnsplashClient] using the provided [_dio] instance.
  ///
  /// In production, pass the result of [createUnsplashDio].
  /// In tests, pass a mock [Dio] instance.
  const UnsplashClient(this._dio);

  final Dio _dio;

  /// Searches for photos matching [query] on the given [page].
  ///
  /// [perPage] defaults to [unsplashPageSize].
  /// [clientId] defaults to [unsplashAccessKey] (injected via `--dart-define`).
  ///
  /// Throws [UnsplashApiException] on non-2xx responses.
  /// Throws [NetworkException] on connectivity failures.
  Future<UnsplashSearchResponse> searchPhotos({
    required String query,
    required int page,
    int perPage = unsplashPageSize,
    String clientId = unsplashAccessKey,
  }) async {
    final Response<Map<String, dynamic>> response = await _dio.get<
        Map<String, dynamic>>(
      unsplashSearchPhotosPath,
      queryParameters: <String, dynamic>{
        'query': query,
        'page': page,
        'per_page': perPage,
        'client_id': clientId,
      },
    );

    return UnsplashSearchResponse.fromJson(
      response.data ?? <String, dynamic>{},
    );
  }
}
