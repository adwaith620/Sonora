import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions.dart';
import '../../data/models/playlist.dart';
import '../../data/providers/playlist_providers.dart';
import '../common/artwork_widget.dart';
import '../common/empty_state.dart';
import '../dialogs/create_playlist_dialog.dart';

/// Playlists screen - shows all user playlists.
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePlaylistDialog(),
          );
        },
        tooltip: 'Create Playlist',
        child: const Icon(Icons.add_rounded),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSmartPlaylists(context, ref, theme),
          _buildUserPlaylists(context, ref, theme),
        ],
      ),
    );
  }

  Widget _buildSmartPlaylists(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final smartPlaylists = ref.watch(smartPlaylistsProvider);

    return smartPlaylists.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final playlist = playlists[index];
            return _buildPlaylistTile(context, playlist, theme);
          }, childCount: playlists.length),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (e, st) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading smart playlists: $e'),
        ),
      ),
    );
  }

  Widget _buildUserPlaylists(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final userPlaylists = ref.watch(userPlaylistsProvider);

    return userPlaylists.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.queue_music_rounded,
              title: 'No playlists',
              description:
                  'Create a playlist to group your favorite songs together.',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Your Playlists',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            final playlist = playlists[index - 1];
            return _buildPlaylistTile(context, playlist, theme);
          }, childCount: playlists.length + 1),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) =>
          SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    Playlist playlist,
    ThemeData theme,
  ) {
    IconData? icon;
    if (playlist.id == 'smart_favorites') {
      icon = Icons.favorite_rounded;
    } else if (playlist.id == 'smart_recently_played') {
      icon = Icons.history_rounded;
    } else if (playlist.id == 'smart_recently_added') {
      icon = Icons.new_releases_rounded;
    } else {
      icon = Icons.queue_music_rounded;
    }

    return ListTile(
      leading: ArtworkWidget(
        artworkPath: playlist.artworkPath,
        size: 48,
        icon: icon,
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        playlist.songCount.plural('song'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        // Need to add route to app_router.dart!
        context.push('/playlists/${playlist.id}');
      },
    );
  }
}
