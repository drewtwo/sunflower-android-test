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

/// Provider-based state management for the gallery feature.
///
/// Mirrors the Android `GalleryViewModel` defined in
/// `viewmodels/GalleryViewModel.kt`. Provides paginated Unsplash photo
/// search results.
///
/// ## Android → Dart mapping
/// | Android                           | Dart                                |
/// |-----------------------------------|-------------------------------------|
/// | `@HiltViewModel`                  | `ChangeNotifier` + `ChangeNotifierProvider` |
/// | `Pager(config, pagingSourceFactory)` | Manual pagination with page tracking |
/// | `Flow<PagingData<UnsplashPhoto>>` | `List<UnsplashPhoto>` + pagination state |
/// | `cachedIn(viewModelScope)`        | In-memory list accumulation         |
/// | `fun refreshData()`               | `refresh()`                         |
///
/// ## Pagination strategy
/// The Android implementation uses Paging 3 (`Pager` + `PagingSource`).
/// This Flutter implementation uses manual pagination with a page counter,
/// which integrates with the `infinite_scroll_pagination` package's
/// `PagingController` in the UI layer.
library;

import 'package:flutter/foundation.dart';
import 'package:sunflower_flutter/data/models/unsplash_photo.dart';
import 'package:sunflower_flutter/data/repositories/unsplash_repository.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Represents the state of the gallery screen.
class GalleryState {
  /// Creates a [GalleryState].
  const GalleryState({
    this.photos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.query = '',
    this.currentPage = 0,
    this.totalPages = 0,
  });

  /// The accumulated list of photos loaded so far.
  final List<UnsplashPhoto> photos;

  /// Whether the initial page is loading.
  final bool isLoading;

  /// Whether an additional page is loading.
  final bool isLoadingMore;

  /// Whether all pages have been loaded.
  final bool hasReachedEnd;

  /// An error message, or `null` if there is no error.
  final String? errorMessage;

  /// The current search query.
  final String query;

  /// The last page that was successfully loaded (1-based).
  final int currentPage;

  /// The total number of pages available for the current query.
  final int totalPages;

  /// Returns `true` if there are more pages to load.
  bool get hasMorePages => !hasReachedEnd && currentPage < totalPages;

  /// Returns a copy of this state with the given fields replaced.
  GalleryState copyWith({
    List<UnsplashPhoto>? photos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    String? query,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) =>
      GalleryState(
        photos: photos ?? this.photos,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        query: query ?? this.query,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for the gallery screen.
///
/// Mirrors the Android `GalleryViewModel` class. Provides paginated
/// Unsplash photo search results with support for infinite scrolling.
///
/// ## Usage
/// ```dart
/// final notifier = GalleryNotifier(
///   query: 'sunflower',
///   repository: getIt<UnsplashRepository>(),
/// );
/// await notifier.loadNextPage();
/// ```
class GalleryNotifier extends ChangeNotifier {
  /// Creates a [GalleryNotifier] for the given [query].
  ///
  /// Immediately loads the first page of results.
  GalleryNotifier({
    required String query,
    required UnsplashRepository repository,
  })  : _repository = repository {
    _state = GalleryState(query: query);
    if (query.isNotEmpty) {
      loadFirstPage();
    }
  }

  final UnsplashRepository _repository;

  GalleryState _state = const GalleryState();

  /// The current state of the gallery.
  GalleryState get state => _state;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads the first page of results for the current query.
  ///
  /// Clears any existing results and resets pagination.
  /// Mirrors `fun refreshData()` in the Android `GalleryViewModel`.
  Future<void> loadFirstPage() async {
    if (_state.isLoading) return;

    _state = _state.copyWith(
      photos: [],
      isLoading: true,
      hasReachedEnd: false,
      currentPage: 0,
      totalPages: 0,
      clearError: true,
    );
    notifyListeners();

    await _loadPage(1);
  }

  /// Loads the next page of results.
  ///
  /// No-op if already loading, or if all pages have been loaded.
  /// Called by the UI when the user scrolls to the bottom of the list.
  Future<void> loadNextPage() async {
    if (_state.isLoading || _state.isLoadingMore || _state.hasReachedEnd) {
      return;
    }
    if (!_state.hasMorePages && _state.currentPage > 0) return;

    _state = _state.copyWith(isLoadingMore: true);
    notifyListeners();

    await _loadPage(_state.currentPage + 1);
  }

  /// Updates the search query and reloads results.
  Future<void> updateQuery(String query) async {
    if (_state.query == query) return;
    _state = _state.copyWith(query: query);
    await loadFirstPage();
  }

  /// Clears any error message from the state.
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadPage(int page) async {
    try {
      final result = await _repository.searchPhotos(
        query: _state.query,
        page: page,
      );

      final List<UnsplashPhoto> updatedPhotos = [
        ..._state.photos,
        ...result.photos,
      ];

      _state = _state.copyWith(
        photos: updatedPhotos,
        isLoading: false,
        isLoadingMore: false,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        hasReachedEnd: !result.hasNextPage,
        clearError: true,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }
}
