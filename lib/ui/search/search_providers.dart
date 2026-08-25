import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/repository_providers.dart';
import '../../services/library_service.dart';

/// Provides the user's search history.
final searchHistoryProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final libraryService = ref.watch(libraryRepositoryProvider);
  return libraryService.watchSearchHistory();
});

/// State for the active search query.
class SearchQueryNotifier extends StateNotifier<String> {
  SearchQueryNotifier() : super('');

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Provider for the active search query.
final searchQueryProvider =
    StateNotifierProvider<SearchQueryNotifier, String>((ref) {
  return SearchQueryNotifier();
});

/// Debounces the search query and returns the results.
final searchResultsProvider =
    FutureProvider.autoDispose<LibrarySearchResult>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final libraryService = ref.watch(libraryRepositoryProvider);

  if (query.isEmpty) {
    return const LibrarySearchResult();
  }

  // Debounce logic
  var didCancel = false;
  ref.onDispose(() => didCancel = true);

  await Future.delayed(const Duration(milliseconds: 300));
  if (didCancel) {
    // If canceled before the delay finishes, just return empty
    // The provider system handles this cancellation gracefully.
    return const LibrarySearchResult();
  }

  return libraryService.search(query);
});
