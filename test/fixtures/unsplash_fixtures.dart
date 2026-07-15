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

/// Unsplash API response fixtures for use in tests.
///
/// Provides pre-built [UnsplashPhoto], [UnsplashPhotoUrls], [UnsplashUser],
/// and [UnsplashSearchResponse] objects for unit tests.
library;

import 'package:sunflower_flutter/data/models/unsplash_photo.dart';
import 'package:sunflower_flutter/data/models/unsplash_search_response.dart';

// ---------------------------------------------------------------------------
// UnsplashPhotoUrls fixtures
// ---------------------------------------------------------------------------

/// A set of photo URLs for the sunflower photo fixture.
const UnsplashPhotoUrls sunflowerPhotoUrls = UnsplashPhotoUrls(
  raw: 'https://images.unsplash.com/photo-sunflower?raw',
  full: 'https://images.unsplash.com/photo-sunflower?full',
  regular: 'https://images.unsplash.com/photo-sunflower?regular',
  small: 'https://images.unsplash.com/photo-sunflower?small',
  thumb: 'https://images.unsplash.com/photo-sunflower?thumb',
);

/// A set of photo URLs for the apple photo fixture.
const UnsplashPhotoUrls applePhotoUrls = UnsplashPhotoUrls(
  raw: 'https://images.unsplash.com/photo-apple?raw',
  full: 'https://images.unsplash.com/photo-apple?full',
  regular: 'https://images.unsplash.com/photo-apple?regular',
  small: 'https://images.unsplash.com/photo-apple?small',
  thumb: 'https://images.unsplash.com/photo-apple?thumb',
);

// ---------------------------------------------------------------------------
// UnsplashUser fixtures
// ---------------------------------------------------------------------------

/// A photographer user fixture.
const UnsplashUser testPhotographer = UnsplashUser(
  name: 'Test Photographer',
  username: 'testphotographer',
);

/// A second photographer user fixture.
const UnsplashUser testPhotographer2 = UnsplashUser(
  name: 'Another Photographer',
  username: 'anotherphotographer',
);

// ---------------------------------------------------------------------------
// UnsplashPhoto fixtures
// ---------------------------------------------------------------------------

/// A sunflower photo fixture.
const UnsplashPhoto sunflowerPhoto = UnsplashPhoto(
  id: 'sunflower-photo-1',
  urls: sunflowerPhotoUrls,
  user: testPhotographer,
);

/// An apple photo fixture.
const UnsplashPhoto applePhoto = UnsplashPhoto(
  id: 'apple-photo-1',
  urls: applePhotoUrls,
  user: testPhotographer2,
);

/// A list of sunflower photos (3 items).
final List<UnsplashPhoto> sunflowerPhotos = List.generate(
  3,
  (i) => UnsplashPhoto(
    id: 'sunflower-photo-$i',
    urls: sunflowerPhotoUrls,
    user: testPhotographer,
  ),
);

/// A list of 25 photos (one full page).
final List<UnsplashPhoto> fullPagePhotos = List.generate(
  25,
  (i) => UnsplashPhoto(
    id: 'photo-$i',
    urls: sunflowerPhotoUrls,
    user: testPhotographer,
  ),
);

// ---------------------------------------------------------------------------
// UnsplashSearchResponse fixtures
// ---------------------------------------------------------------------------

/// A search response with 3 sunflower photos (1 of 1 pages).
final UnsplashSearchResponse sunflowerSearchResponse = UnsplashSearchResponse(
  results: sunflowerPhotos,
  totalPages: 1,
);

/// A search response with a full page of 25 photos (1 of 5 pages).
final UnsplashSearchResponse fullPageSearchResponse = UnsplashSearchResponse(
  results: fullPagePhotos,
  totalPages: 5,
);

/// An empty search response (no results).
const UnsplashSearchResponse emptySearchResponse = UnsplashSearchResponse(
  results: [],
  totalPages: 0,
);

// ---------------------------------------------------------------------------
// JSON fixtures
// ---------------------------------------------------------------------------

/// A JSON map representing a single [UnsplashPhoto].
Map<String, dynamic> unsplashPhotoJson({
  String id = 'test-photo-id',
}) =>
    {
      'id': id,
      'urls': {
        'raw': 'https://images.unsplash.com/photo?raw',
        'full': 'https://images.unsplash.com/photo?full',
        'regular': 'https://images.unsplash.com/photo?regular',
        'small': 'https://images.unsplash.com/photo?small',
        'thumb': 'https://images.unsplash.com/photo?thumb',
      },
      'user': {
        'name': 'Test User',
        'username': 'testuser',
      },
    };

/// A JSON map representing an [UnsplashSearchResponse].
Map<String, dynamic> unsplashSearchResponseJson({
  int count = 3,
  int totalPages = 1,
}) =>
    {
      'results': List.generate(count, (i) => unsplashPhotoJson(id: 'photo-$i')),
      'total_pages': totalPages,
    };
