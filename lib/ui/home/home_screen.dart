import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../data/models/album.dart';
import '../../data/models/artist.dart';
import '../../data/models/song.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';
import '../common/artwork_widget.dart';
import '../common/section_header.dart';
import '../common/song_list_tile.dart';
import '../../data/providers/audio_provider.dart';
import '../favorites/favorites_screen.dart'; // For favoriteSongsProvider
import 'home_providers.dart';

/// Home screen — the main landing page of Sonora.
///
/// Shows carousels for recently played, recently added, favorites,
/// albums, and artists connected to the real Drift database.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteSongsProvider);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedSongsProvider);
    final recentlyAddedAsync = ref.watch(recentlyAddedSongsProvider);
    final albumsAsync = ref.watch(homeAlbumsProvider);
    final artistsAsync = ref.watch(homeArtistsProvider);

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
          _buildAsyncSongList(context, ref, recentlyPlayedAsync),

          // Recently Added
          const SectionHeader(title: 'Recently Added', actionLabel: 'See all'),
          _buildAsyncSongList(context, ref, recentlyAddedAsync),

          // Favorites
          const SectionHeader(title: 'Favorites', actionLabel: 'See all'),
          _buildAsyncSongList(context, ref, favoritesAsync),

          // Your Albums
          const SectionHeader(title: 'Your Albums', actionLabel: 'See all'),
          _buildAsyncAlbumCarousel(context, albumsAsync),

          // Your Artists
          const SectionHeader(title: 'Your Artists', actionLabel: 'See all'),
          _buildAsyncArtistCarousel(context, artistsAsync),

          // Bottom padding for mini player
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildAsyncSongList(BuildContext context, WidgetRef ref, AsyncValue<List<Song>> asyncData) {
    return asyncData.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Text('Nothing here yet.'),
          );
        }
        return Column(
          children: songs.take(5).map((song) {
            return SongListTile(
              song: song,
              onTap: () {
                final audioService = ref.read(audioPlayerServiceProvider);
                audioService.playQueue(songs, startIndex: songs.indexOf(song));
              },
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildAsyncAlbumCarousel(
    BuildContext context,
    AsyncValue<List<Album>> asyncData,
  ) {
    return asyncData.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Text('No albums found.'),
          );
        }
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            itemCount: albums.length > 10 ? 10 : albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return SizedBox(
                width: 150,
                child: AlbumGridTile(
                  album: album,
                  onTap: () => context.push('/albums/${album.id}'),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) =>
          SizedBox(height: 200, child: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildAsyncArtistCarousel(
    BuildContext context,
    AsyncValue<List<Artist>> asyncData,
  ) {
    return asyncData.when(
      data: (artists) {
        if (artists.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Text('No artists found.'),
          );
        }
        final theme = Theme.of(context);
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            itemCount: artists.length > 10 ? 10 : artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return InkWell(
                onTap: () => context.push('/artists/${artist.id}'),
                borderRadius: BorderRadius.circular(Spacing.sm),
                child: Padding(
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
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) =>
          SizedBox(height: 120, child: Center(child: Text('Error: $err'))),
    );
  }
}
