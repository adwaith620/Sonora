import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';
import '../common/empty_state.dart';
import '../common/song_list_tile.dart';
import 'search_providers.dart';

/// Search screen with M3 SearchBar, categorized results, and history.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Synchronize initial state
    final currentQuery = ref.read(searchQueryProvider);
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final q = query.trim();
    if (q.isNotEmpty) {
      ref.read(libraryRepositoryProvider).saveSearchQuery(q);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: query.isEmpty,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search songs, albums, artists...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).setQuery(value);
          },
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).clear();
                _focusNode.requestFocus();
              },
            ),
        ],
      ),
      body: query.isEmpty ? _buildHistory(theme) : _buildResults(theme),
    );
  }

  Widget _buildHistory(ThemeData theme) {
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Search your library',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(libraryRepositoryProvider).clearSearchHistory();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            for (final item in history)
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    ref.read(libraryRepositoryProvider).removeSearchQuery(item);
                  },
                ),
                onTap: () {
                  _searchController.text = item;
                  _searchController.selection = TextSelection.collapsed(
                    offset: item.length,
                  );
                  ref.read(searchQueryProvider.notifier).setQuery(item);
                  _onSearchSubmitted(item);
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Error loading history',
        description: e.toString(),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      data: (results) {
        if (results.songs.isEmpty &&
            results.albums.isEmpty &&
            results.artists.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(Spacing.xxxl),
            child: Center(
              child: Text(
                'No results for "${_searchController.text}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Artists
            if (results.artists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.sm,
                  ),
                  child: Text(
                    'Artists',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final artist = results.artists[index];
                  return ListTile(
                    leading: ArtworkWidget(
                      artworkPath: artist.artworkPath,
                      size: 40,
                      borderRadius: BorderRadius.circular(20),
                      icon: Icons.person_rounded,
                    ),
                    title: Text(artist.name),
                    onTap: () {
                      _onSearchSubmitted(_searchController.text);
                      context.push('/artists/${artist.id}');
                    },
                  );
                }, childCount: results.artists.length),
              ),
            ],

            // Albums
            if (results.albums.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.sm,
                  ),
                  child: Text(
                    'Albums',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final album = results.albums[index];
                  return ListTile(
                    leading: ArtworkWidget(
                      artworkPath: album.artworkPath,
                      size: 40,
                      borderRadius: BorderRadius.circular(8),
                      icon: Icons.album_rounded,
                    ),
                    title: Text(album.name),
                    subtitle: Text(album.artist),
                    onTap: () {
                      _onSearchSubmitted(_searchController.text);
                      context.push('/albums/${album.id}');
                    },
                  );
                }, childCount: results.albums.length),
              ),
            ],

            // Songs
            if (results.songs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.sm,
                  ),
                  child: Text(
                    'Songs',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = results.songs[index];
                  return SongListTile(
                    song: song,
                    onTap: () {
                      _onSearchSubmitted(_searchController.text);
                      ref
                          .read(audioPlayerServiceProvider)
                          .playQueue(results.songs, startIndex: index);
                    },
                  );
                }, childCount: results.songs.length),
              ),
            ],

            // Padding at bottom
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.xxl)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Search failed',
        description: e.toString(),
      ),
    );
  }
}
