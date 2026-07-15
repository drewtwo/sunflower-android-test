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

/// Unit tests for [UnsplashRepository].
///
/// Tests search pagination, error handling, and the convenience methods
/// [getInitialSearchResults] and [searchPhotos]. Uses [mocktail] to mock
/// [UnsplashClient] and avoid real network calls.
///
/// Mirrors the Android `UnsplashPagingSource` test logic, adapted for
/// the Dart pagination model.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';
import 'package:sunflower_flutter/data/models/unsplash_photo.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';
import 'package:sunflower_flutter/data/repositories/unsplash_repository.dart';

import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_services.dart';
import '../../fixtures/unsplash_fixtures.dart';

void main() {
  late MockUnsplashClient mockClient;
  late UnsplashRepository repository;

  setUpAll(registerServiceFallbackValues);

  setUp(() {
    mockClient = MockUnsplashClient();
    repository = UnsplashRepository(mockClient);
  });

  // -------------------------------------------------------------------------
  // searchPhotos
  // -------------------------------------------------------------------------

  group('searchPhotos', () {
    test('returns UnsplashPageResult with photos and pagination metadata',
        () async {
      // Arrange
      when(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => sunflowerSearchResponse);

      // Act
      final UnsplashPageResult result = await repository.searchPhotos(
        query: 'sunflower',
        page: 1,
      );

      // Assert
      expect(result.photos.length, equals(3));
      expect(result.currentPage, equals(1));
      expect(result.totalPages, equals(1));
      expect(result.query, equals('sunflower'));
    });

    test('returns correct hasNextPage when more pages exist', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'rose',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => fullPageSearchResponse);

      final UnsplashPageResult result = await repository.searchPhotos(
        query: 'rose',
        page: 1,
      );

      expect(result.hasNextPage, isTrue);
      expect(result.nextPage, equals(2));
      expect(result.totalPages, equals(5));
    });

    test('returns hasNextPage = false on last page', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => sunflowerSearchResponse); // totalPages = 1

      final UnsplashPageResult result = await repository.searchPhotos(
        query: 'sunflower',
        page: 1,
      );

      expect(result.hasNextPage, isFalse);
      expect(result.nextPage, isNull);
    });

    test('returns empty photos list for empty search response', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'xyzzy',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => emptySearchResponse);

      final UnsplashPageResult result = await repository.searchPhotos(
        query: 'xyzzy',
        page: 1,
      );

      expect(result.photos, isEmpty);
      expect(result.totalPages, equals(0));
      expect(result.hasNextPage, isFalse);
    });

    test('passes correct page number to client', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'tulip',
          page: 3,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => fullPageSearchResponse);

      final UnsplashPageResult result = await repository.searchPhotos(
        query: 'tulip',
        page: 3,
      );

      expect(result.currentPage, equals(3));
      verify(
        () => mockClient.searchPhotos(
          query: 'tulip',
          page: 3,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });

    test('uses default perPage of networkPageSize', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'daisy',
          page: 1,
          perPage: networkPageSize,
        ),
      ).thenAnswer((_) async => sunflowerSearchResponse);

      await repository.searchPhotos(query: 'daisy', page: 1);

      verify(
        () => mockClient.searchPhotos(
          query: 'daisy',
          page: 1,
          perPage: networkPageSize,
        ),
      ).called(1);
    });

    test('propagates exceptions from client', () async {
      when(
        () => mockClient.searchPhotos(
          query: any(named: 'query'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () => repository.searchPhotos(query: 'sunflower', page: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('returns full page of 25 photos', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'flower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => fullPageSearchResponse);

      final UnsplashPageResult result = await repository.searchPhotos(
        query: 'flower',
        page: 1,
      );

      expect(result.photos.length, equals(25));
    });
  });

  // -------------------------------------------------------------------------
  // getInitialSearchResults
  // -------------------------------------------------------------------------

  group('getInitialSearchResults', () {
    test('fetches page 1 for the given query', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => sunflowerSearchResponse);

      final UnsplashPageResult result =
          await repository.getInitialSearchResults('sunflower');

      expect(result.currentPage, equals(1));
      expect(result.query, equals('sunflower'));
      verify(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });

    test('returns photos from first page', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => sunflowerSearchResponse);

      final UnsplashPageResult result =
          await repository.getInitialSearchResults('sunflower');

      expect(result.photos, isNotEmpty);
      expect(result.photos.first.id, startsWith('sunflower-photo-'));
    });
  });

  // -------------------------------------------------------------------------
  // UnsplashPageResult
  // -------------------------------------------------------------------------

  group('UnsplashPageResult', () {
    test('hasNextPage is true when currentPage < totalPages', () {
      const result = UnsplashPageResult(
        photos: [],
        currentPage: 2,
        totalPages: 5,
        query: 'test',
      );
      expect(result.hasNextPage, isTrue);
      expect(result.nextPage, equals(3));
    });

    test('hasNextPage is false when currentPage == totalPages', () {
      const result = UnsplashPageResult(
        photos: [],
        currentPage: 5,
        totalPages: 5,
        query: 'test',
      );
      expect(result.hasNextPage, isFalse);
      expect(result.nextPage, isNull);
    });

    test('hasNextPage is false when totalPages is 0', () {
      const result = UnsplashPageResult(
        photos: [],
        currentPage: 1,
        totalPages: 0,
        query: 'test',
      );
      expect(result.hasNextPage, isFalse);
    });
  });
}
