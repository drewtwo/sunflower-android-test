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

/// Integration tests for Unsplash gallery search and pagination.
///
/// Tests the gallery search flow including:
/// - Initial search results
/// - Pagination (loading subsequent pages)
/// - Empty results handling
/// - Error handling
///
/// Uses mock HTTP responses to avoid real network calls, mirroring the
/// Android approach of mocking Retrofit services in instrumented tests.
///
/// ## Running
/// ```sh
/// flutter test integration_test/gallery_pagination_test.dart
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sunflower_flutter/data/datasources/unsplash_client.dart';
import 'package:sunflower_flutter/data/models/unsplash_photo.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';
import 'package:sunflower_flutter/data/repositories/unsplash_repository.dart';

// ---------------------------------------------------------------------------
// Mock HTTP client
// ---------------------------------------------------------------------------

class _MockUnsplashClient extends Mock implements UnsplashClient {}

// ---------------------------------------------------------------------------
// Test data factories
// ---------------------------------------------------------------------------

/// Creates a list of [UnsplashPhoto] objects for testing.
List<UnsplashPhoto> _makePhotos(int count, {String prefix = 'photo'}) =>
    List.generate(
      count,
      (i) => UnsplashPhoto(
        id: '$prefix-$i',
        urls: const UnsplashPhotoUrls(
          small: 'https://example.com/small.jpg',
          regular: 'https://example.com/regular.jpg',
        ),
        user: const UnsplashUser(
          name: 'Test User',
          attributionUrl: 'https://unsplash.com/@testuser',
        ),
      ),
    );

/// Creates an [UnsplashSearchResponse] with [count] photos.
UnsplashSearchResponse _makeResponse(
  int count, {
  int totalPages = 1,
}) =>
    UnsplashSearchResponse(
      results: _makePhotos(count),
      totalPages: totalPages,
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockUnsplashClient mockClient;
  late UnsplashRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const UnsplashSearchResponse(results: [], totalPages: 0),
    );
  });

  setUp(() {
    mockClient = _MockUnsplashClient();
    repository = UnsplashRepository(mockClient);
  });

  // -------------------------------------------------------------------------
  // Initial search
  // -------------------------------------------------------------------------

  group('Initial search', () {
    test('returns first page of results for query', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _makeResponse(10, totalPages: 3));

      final result = await repository.getInitialSearchResults('sunflower');

      expect(result.photos.length, equals(10));
      expect(result.currentPage, equals(1));
      expect(result.totalPages, equals(3));
      expect(result.query, equals('sunflower'));
      expect(result.hasNextPage, isTrue);
    });

    test('returns empty results for query with no matches', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'xyzzy-nonexistent',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => const UnsplashSearchResponse(results: [], totalPages: 0),
      );

      final result =
          await repository.getInitialSearchResults('xyzzy-nonexistent');

      expect(result.photos, isEmpty);
      expect(result.totalPages, equals(0));
      expect(result.hasNextPage, isFalse);
      expect(result.nextPage, isNull);
    });

    test('returns full page of 25 photos', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'flower',
          page: 1,
          perPage: networkPageSize,
        ),
      ).thenAnswer((_) async => _makeResponse(25, totalPages: 5));

      final result = await repository.getInitialSearchResults('flower');

      expect(result.photos.length, equals(25));
    });
  });

  // -------------------------------------------------------------------------
  // Pagination
  // -------------------------------------------------------------------------

  group('Pagination', () {
    test('can load subsequent pages', () async {
      // Page 1
      when(
        () => mockClient.searchPhotos(
          query: 'rose',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _makeResponse(25, totalPages: 3));

      // Page 2
      when(
        () => mockClient.searchPhotos(
          query: 'rose',
          page: 2,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _makeResponse(25, totalPages: 3));

      // Page 3 (last)
      when(
        () => mockClient.searchPhotos(
          query: 'rose',
          page: 3,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _makeResponse(15, totalPages: 3));

      final page1 = await repository.searchPhotos(query: 'rose', page: 1);
      expect(page1.hasNextPage, isTrue);
      expect(page1.nextPage, equals(2));

      final page2 = await repository.searchPhotos(query: 'rose', page: 2);
      expect(page2.hasNextPage, isTrue);
      expect(page2.nextPage, equals(3));

      final page3 = await repository.searchPhotos(query: 'rose', page: 3);
      expect(page3.hasNextPage, isFalse);
      expect(page3.nextPage, isNull);
      expect(page3.photos.length, equals(15));
    });

    test('hasNextPage is false on single-page result', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'rare-plant',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _makeResponse(3, totalPages: 1));

      final result = await repository.searchPhotos(query: 'rare-plant', page: 1);

      expect(result.hasNextPage, isFalse);
      expect(result.nextPage, isNull);
    });

    test('page numbers are tracked correctly across pages', () async {
      for (int page = 1; page <= 5; page++) {
        when(
          () => mockClient.searchPhotos(
            query: 'tulip',
            page: page,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => _makeResponse(25, totalPages: 5));

        final result =
            await repository.searchPhotos(query: 'tulip', page: page);
        expect(result.currentPage, equals(page));
      }
    });

    test('total pages is consistent across page fetches', () async {
      for (int page = 1; page <= 3; page++) {
        when(
          () => mockClient.searchPhotos(
            query: 'daisy',
            page: page,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => _makeResponse(25, totalPages: 3));

        final result =
            await repository.searchPhotos(query: 'daisy', page: page);
        expect(result.totalPages, equals(3));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Lazy loading simulation
  // -------------------------------------------------------------------------

  group('Lazy loading', () {
    test('accumulates photos across multiple page loads', () async {
      final allPhotos = <UnsplashPhoto>[];

      for (int page = 1; page <= 3; page++) {
        when(
          () => mockClient.searchPhotos(
            query: 'orchid',
            page: page,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => UnsplashSearchResponse(
            results: _makePhotos(10, prefix: 'orchid-page$page'),
            totalPages: 3,
          ),
        );

        final result =
            await repository.searchPhotos(query: 'orchid', page: page);
        allPhotos.addAll(result.photos);
      }

      expect(allPhotos.length, equals(30));

      // Verify photos from each page are distinct.
      final ids = allPhotos.map((p) => p.id).toSet();
      expect(ids.length, equals(30));
    });

    test('query is preserved across page loads', () async {
      for (int page = 1; page <= 2; page++) {
        when(
          () => mockClient.searchPhotos(
            query: 'lavender',
            page: page,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => _makeResponse(25, totalPages: 2));

        final result =
            await repository.searchPhotos(query: 'lavender', page: page);
        expect(result.query, equals('lavender'));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('Error handling', () {
    test('propagates network errors', () async {
      when(
        () => mockClient.searchPhotos(
          query: any(named: 'query'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(Exception('Network error: connection refused'));

      expect(
        () => repository.searchPhotos(query: 'sunflower', page: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('propagates API errors', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'sunflower',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(Exception('API error: 401 Unauthorized'));

      expect(
        () => repository.searchPhotos(query: 'sunflower', page: 1),
        throwsA(isA<Exception>()),
      );
    });

    test('error on page 2 does not affect page 1 results', () async {
      when(
        () => mockClient.searchPhotos(
          query: 'iris',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => _makeResponse(25, totalPages: 2));

      when(
        () => mockClient.searchPhotos(
          query: 'iris',
          page: 2,
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(Exception('Network error'));

      // Page 1 succeeds.
      final page1 = await repository.searchPhotos(query: 'iris', page: 1);
      expect(page1.photos.length, equals(25));

      // Page 2 fails.
      expect(
        () => repository.searchPhotos(query: 'iris', page: 2),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // UnsplashPageResult model
  // -------------------------------------------------------------------------

  group('UnsplashPageResult', () {
    test('nextPage increments correctly', () {
      const result = UnsplashPageResult(
        photos: [],
        currentPage: 3,
        totalPages: 10,
        query: 'test',
      );
      expect(result.nextPage, equals(4));
    });

    test('hasNextPage is false when on last page', () {
      const result = UnsplashPageResult(
        photos: [],
        currentPage: 10,
        totalPages: 10,
        query: 'test',
      );
      expect(result.hasNextPage, isFalse);
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
