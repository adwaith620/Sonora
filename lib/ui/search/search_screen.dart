import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';
import '../common/song_list_tile.dart';

/// Search screen with M3 SearchBar and categorized results.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Simple filter for Phase 1
    final filteredSongs = _query.isEmpty
        ? <dynamic>[]
        : mockSongs.where((s) {
            final q = _query.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.artist.toLowerCase().contains(q) ||
                s.album.toLowerCase().contains(q);
          }).toList();

    final filteredAlbums = _query.isEmpty
        ? <dynamic>[]
        : mockAlbums.where((a) {
            final q = _query.toLowerCase();
            return a.name.toLowerCase().contains(q) ||
                a.artist.toLowerCase().contains(q);
          }).toList();

    final filteredArtists = _query.isEmpty
        ? <dynamic>[]
        : mockArtists.where((a) {
            return a.name.toLowerCase().contains(_query.toLowerCase());
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search songs, albums, artists...',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
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
            )
          : ListView(
              children: [
                // Artists
                if (filteredArtists.isNotEmpty) ...[
                  Padding(
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
                      ),
                    ),
                  ),
                  for (final artist in filteredArtists)
                    ListTile(
                      leading: ArtworkWidget(
                        artworkPath: artist.artworkPath,
                        size: 40,
                        borderRadius: BorderRadius.circular(20),
                        icon: Icons.person_rounded,
                      ),
                      title: Text(artist.name),
                      onTap: () {},
                    ),
                ],

                // Albums
                if (filteredAlbums.isNotEmpty) ...[
                  Padding(
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
                      ),
                    ),
                  ),
                  for (final album in filteredAlbums)
                    ListTile(
                      leading: ArtworkWidget(
                        artworkPath: album.artworkPath,
                        size: 40,
                        icon: Icons.album_rounded,
                      ),
                      title: Text(album.name),
                      subtitle: Text(album.artist),
                      onTap: () {},
                    ),
                ],

                // Songs
                if (filteredSongs.isNotEmpty) ...[
                  Padding(
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
                      ),
                    ),
                  ),
                  for (final song in filteredSongs)
                    SongListTile(song: song, onTap: () {}),
                ],

                // No results
                if (filteredSongs.isEmpty &&
                    filteredAlbums.isEmpty &&
                    filteredArtists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Spacing.xxxl),
                    child: Center(
                      child: Text(
                        'No results for "$_query"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
