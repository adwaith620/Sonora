import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../data/models/album.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';
import '../common/song_list_tile.dart';

final albumDetailProvider =
    FutureProvider.family<({Album? album, List<Song> songs}), String>((
      ref,
      id,
    ) async {
      final db = ref.watch(libraryRepositoryProvider);
      final album = await db.getAlbumById(id);
      final songs = await db.getSongsForAlbum(id);
      return (album: album, songs: songs);
    });

/// Album detail screen — shows album artwork, metadata, and track list.
class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final detailAsync = ref.watch(albumDetailProvider(albumId));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final album = data.album;
          final albumSongs = data.songs;

          if (album == null) {
            return const CustomScrollView(
              slivers: [
                SliverAppBar(pinned: true),
                SliverFillRemaining(
                  child: Center(child: Text('Album not found')),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              // Collapsing app bar with artwork
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _AlbumHeader(album: album),
                ),
              ),

              // Action buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: albumSongs.isEmpty
                              ? null
                              : () {
                                  audioService.playQueue(albumSongs);
                                },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: albumSongs.isEmpty
                              ? null
                              : () {
                                  audioService.playQueue(albumSongs);
                                  audioService.toggleShuffle();
                                },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Track list
              if (albumSongs.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No tracks found for this album.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return SongListTile(
                      song: albumSongs[index],
                      showTrackNumber: true,
                      onTap: () {
                        audioService.playQueue(albumSongs, startIndex: index);
                      },
                    );
                  }, childCount: albumSongs.length),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: kMiniPlayerHeight + Spacing.md),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48), // AppBar height
            ArtworkWidget(
              artworkPath: album.artworkPath,
              size: 180,
              borderRadius: BorderRadius.circular(Radii.large),
              icon: Icons.album_rounded,
              iconSize: 64,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              album.name,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              album.year != null
                  ? '${album.artist} • ${album.year} • ${album.songCount.plural('track')}'
                  : '${album.artist} • ${album.songCount.plural('track')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
