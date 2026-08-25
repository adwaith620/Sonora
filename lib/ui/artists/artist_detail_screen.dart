import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../data/models/album.dart';
import '../../data/models/artist.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';
import '../common/artwork_widget.dart';
import '../common/section_header.dart';
import '../common/song_list_tile.dart';

final artistDetailProvider =
    FutureProvider.family<
      ({Artist? artist, List<Album> albums, List<Song> songs}),
      String
    >((ref, id) async {
      final db = ref.watch(libraryRepositoryProvider);
      final artist = await db.getArtistById(id);
      final albums = await db.getAlbumsForArtist(id);
      final songs = await db.getSongsForArtist(id);
      return (artist: artist, albums: albums, songs: songs);
    });

/// Artist detail screen — shows artist info, albums, and songs.
class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioService = ref.read(audioPlayerServiceProvider);
    final detailAsync = ref.watch(artistDetailProvider(artistId));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final artist = data.artist;
          final artistAlbums = data.albums;
          final artistSongs = data.songs;

          if (artist == null) {
            return CustomScrollView(
              slivers: [
                const SliverAppBar(pinned: true),
                const SliverFillRemaining(
                  child: Center(child: Text('Artist not found')),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          ArtworkWidget(
                            artworkPath: artist.artworkPath,
                            size: 96,
                            borderRadius: BorderRadius.circular(48),
                            icon: Icons.person_rounded,
                            iconSize: 40,
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            artist.name,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            '${artist.songCount.plural('song')} • ${artist.albumCount.plural('album')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                          onPressed: artistSongs.isEmpty
                              ? null
                              : () {
                                  audioService.playQueue(artistSongs);
                                },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: artistSongs.isEmpty
                              ? null
                              : () {
                                  audioService.playQueue(artistSongs);
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

              // Albums section
              if (artistAlbums.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionHeader(title: 'Albums')),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                      ),
                      itemCount: artistAlbums.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 150,
                          child: AlbumGridTile(
                            album: artistAlbums[index],
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/album',
                                arguments: artistAlbums[index].id,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Songs section
              if (artistSongs.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionHeader(title: 'Songs')),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return SongListTile(
                      song: artistSongs[index],
                      onTap: () {
                        audioService.playQueue(artistSongs, startIndex: index);
                      },
                    );
                  }, childCount: artistSongs.length),
                ),
              ] else
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(Spacing.xl),
                    child: Center(
                      child: Text('No songs found for this artist.'),
                    ),
                  ),
                ),

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
