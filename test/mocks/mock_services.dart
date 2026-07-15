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

/// Mock service implementations for use in unit tests.
///
/// Provides mock classes for [UnsplashService] and [UnsplashClient] using
/// [mocktail]. Mirrors the Android pattern of mocking Retrofit services in
/// ViewModel tests.
///
/// ## Usage
/// ```dart
/// import 'package:sunflower_flutter/test/mocks/mock_services.dart';
///
/// void main() {
///   late MockUnsplashClient mockClient;
///
///   setUp(() {
///     mockClient = MockUnsplashClient();
///     when(() => mockClient.searchPhotos(
///       query: any(named: 'query'),
///       page: any(named: 'page'),
///       perPage: any(named: 'perPage'),
///     )).thenAnswer((_) async => emptySearchResponse);
///   });
/// }
/// ```
library;

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_service.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';

// ---------------------------------------------------------------------------
// Mock HTTP / service classes
// ---------------------------------------------------------------------------

/// Mock implementation of [UnsplashClient].
///
/// Use with [mocktail] to stub HTTP responses without making real network
/// calls. Mirrors the Android pattern of mocking Retrofit services.
///
/// Example:
/// ```dart
/// final mock = MockUnsplashClient();
/// when(() => mock.searchPhotos(
///   query: 'sunflower',
///   page: 1,
///   perPage: 25,
/// )).thenAnswer((_) async => sunflowerSearchResponse);
/// ```
class MockUnsplashClient extends Mock implements UnsplashClient {}

/// Mock implementation of [UnsplashService].
///
/// Use when testing components that depend on [UnsplashService] rather than
/// [UnsplashClient] directly.
class MockUnsplashService extends Mock implements UnsplashService {}

/// Mock implementation of [Dio].
///
/// Use for low-level HTTP interception in tests that need to verify
/// request/response details.
class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Fallback values
// ---------------------------------------------------------------------------

/// Registers fallback values for [mocktail] matchers used with service mocks.
///
/// Call this in `setUpAll` before using `any()` matchers with custom types.
///
/// Example:
/// ```dart
/// setUpAll(registerServiceFallbackValues);
/// ```
void registerServiceFallbackValues() {
  registerFallbackValue(
    const UnsplashSearchResponse(results: [], totalPages: 0),
  );
  registerFallbackValue(RequestOptions(path: ''));
}

// ---------------------------------------------------------------------------
// Stub helpers
// ---------------------------------------------------------------------------

/// Configures [mockClient] to return [response] for any search query.
///
/// Convenience helper for tests that don't care about the specific query.
void stubSearchPhotos(
  MockUnsplashClient mockClient,
  UnsplashSearchResponse response,
) {
  when(
    () => mockClient.searchPhotos(
      query: any(named: 'query'),
      page: any(named: 'page'),
      perPage: any(named: 'perPage'),
    ),
  ).thenAnswer((_) async => response);
}

/// Configures [mockClient] to throw [exception] for any search query.
///
/// Use this to test error handling in components that use [UnsplashClient].
void stubSearchPhotosError(
  MockUnsplashClient mockClient,
  Exception exception,
) {
  when(
    () => mockClient.searchPhotos(
      query: any(named: 'query'),
      page: any(named: 'page'),
      perPage: any(named: 'perPage'),
    ),
  ).thenThrow(exception);
}

/// Configures [mockClient] to return [response] for a specific [query].
void stubSearchPhotosForQuery(
  MockUnsplashClient mockClient,
  String query,
  UnsplashSearchResponse response,
) {
  when(
    () => mockClient.searchPhotos(
      query: query,
      page: any(named: 'page'),
      perPage: any(named: 'perPage'),
    ),
  ).thenAnswer((_) async => response);
}
