import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/mock_data.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';
import '../common/artwork_widget.dart';
import '../common/section_header.dart';
import '../common/song_list_tile.dart';
import '../favorites/favorites_screen.dart'; // For favoriteSongsProvider

/// Home screen — the main landing page of Sonora.
///
/// Shows carousels for recently played, recently added, favorites,
/// albums, and artists in an OpenTune-inspired layout.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteSongsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {},
        ),
        title: const Text(kAppName),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          // Recently Played
          const SectionHeader(title: 'Recently Played', actionLabel: 'See all'),
          _buildAlbumCarousel(context),

          // Recently Added
          const SectionHeader(title: 'Recently Added', actionLabel: 'See all'),
          _buildSongCarousel(context, mockSongs.take(5).toList()),

          // Favorites
          const SectionHeader(title: 'Favorites', actionLabel: 'See all'),
          favoritesAsync.when(
            data: (songs) => songs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Spacing.md),
                    child: Text('No favorites yet.'),
                  )
                : _buildSongCarousel(context, songs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),

          // Your Albums
          const SectionHeader(title: 'Your Albums', actionLabel: 'See all'),
          _buildAlbumCarousel(context),

          // Your Artists
          const SectionHeader(title: 'Your Artists', actionLabel: 'See all'),
          _buildArtistCarousel(context),

          // Bottom padding for mini player
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildAlbumCarousel(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: mockAlbums.length,
        itemBuilder: (context, index) {
          final album = mockAlbums[index];
          return SizedBox(
            width: 150,
            child: AlbumGridTile(album: album, onTap: () {}),
          );
        },
      ),
    );
  }

  Widget _buildSongCarousel(BuildContext context, List songs) {
    return Column(
      children: [
        for (final song in songs) SongListTile(song: song, onTap: () {}),
      ],
    );
  }

  Widget _buildArtistCarousel(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        itemCount: mockArtists.length,
        itemBuilder: (context, index) {
          final artist = mockArtists[index];
          return Padding(
            padding: const EdgeInsets.only(right: Spacing.lg),
            child: Column(
              children: [
                ArtworkWidget(
                  artworkPath: artist.artworkPath,
                  size: 72,
                  borderRadius: BorderRadius.circular(36),
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: Spacing.sm),
                SizedBox(
                  width: 80,
                  child: Text(
                    artist.name,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
