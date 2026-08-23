import 'package:flutter/material.dart';

import '../../core/extensions.dart';
import '../../data/mock_data.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';
import '../common/artwork_widget.dart';
import '../common/section_header.dart';
import '../common/song_list_tile.dart';

/// Artist detail screen — shows artist info, albums, and songs.
class ArtistDetailScreen extends StatelessWidget {
  const ArtistDetailScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = mockArtists.firstWhere(
      (a) => a.id == artistId,
      orElse: () => mockArtists.first,
    );
    final artistSongs = mockSongs
        .where((s) => s.artist == artist.name)
        .toList();
    final artistAlbums = mockAlbums
        .where((a) => a.artist == artist.name)
        .toList();

    return Scaffold(
      body: CustomScrollView(
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
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
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
                      Text(artist.name, style: theme.textTheme.headlineSmall),
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
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play All'),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {},
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
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  itemCount: artistAlbums.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 150,
                      child: AlbumGridTile(
                        album: artistAlbums[index],
                        onTap: () {},
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Songs section
          const SliverToBoxAdapter(child: SectionHeader(title: 'Songs')),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return SongListTile(song: artistSongs[index], onTap: () {});
            }, childCount: artistSongs.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
