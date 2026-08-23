import 'package:flutter/material.dart';

import '../../core/extensions.dart';
import '../../data/mock_data.dart';
import '../common/artwork_widget.dart';

/// Playlists screen — shows all user playlists.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Create Playlist',
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView.builder(
        itemCount: mockPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = mockPlaylists[index];
          return ListTile(
            leading: ArtworkWidget(
              artworkPath: playlist.artworkPath,
              size: 48,
              icon: playlist.isFavorites
                  ? Icons.favorite_rounded
                  : Icons.queue_music_rounded,
            ),
            title: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              playlist.songCount.plural('song'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          );
        },
      ),
    );
  }
}
