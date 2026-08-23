import 'package:flutter/material.dart';

import '../../core/extensions.dart';
import '../../data/mock_data.dart';
import '../../data/models/album.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';
import '../common/song_list_tile.dart';

/// Album detail screen — shows album artwork, metadata, and track list.
class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context) {
    // In Phase 1, find album from mock data
    final album = mockAlbums.firstWhere(
      (a) => a.id == albumId,
      orElse: () => mockAlbums.first,
    );
    final albumSongs = mockSongs.where((s) => s.album == album.name).toList();

    return Scaffold(
      body: CustomScrollView(
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
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
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

          // Track list
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return SongListTile(
                song: albumSongs[index],
                showTrackNumber: true,
                onTap: () {},
              );
            }, childCount: albumSongs.length),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
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
