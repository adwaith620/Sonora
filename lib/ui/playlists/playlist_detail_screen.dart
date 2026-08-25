import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/playlist_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../common/artwork_widget.dart';
import '../common/empty_state.dart';
import '../common/song_list_tile.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistProvider(playlistId));
    final songsAsync = ref.watch(playlistSongsProvider(playlistId));
    final theme = Theme.of(context);

    return Scaffold(
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Playlist not found')),
            );
          }
          return CustomScrollView(
            slivers: [
              _buildAppBar(
                context,
                ref,
                playlist,
                songsAsync.valueOrNull ?? [],
                theme,
              ),
              _buildSongsList(context, ref, playlist, songsAsync, theme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    List<Song> songs,
    ThemeData theme,
  ) {
    IconData? icon;
    if (playlist.id == 'smart_favorites')
      icon = Icons.favorite_rounded;
    else if (playlist.id == 'smart_recently_played')
      icon = Icons.history_rounded;
    else if (playlist.id == 'smart_recently_added')
      icon = Icons.new_releases_rounded;
    else
      icon = Icons.queue_music_rounded;

    final isSmart = playlist.id.startsWith('smart_');

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      actions: [
        if (!isSmart)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'rename') {
                _showRenameDialog(context, ref, playlist);
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref, playlist);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Text('Rename Playlist'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Playlist'),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16, right: 16),
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background blur/gradient could go here
            ColoredBox(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: ArtworkWidget(
                    artworkPath: playlist.artworkPath,
                    size: 160,
                    borderRadius: BorderRadius.circular(12),
                    icon: icon,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  playlist.songCount.plural('song'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    AsyncValue<List<Song>> songsAsync,
    ThemeData theme,
  ) {
    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.music_note_rounded,
              title: 'Empty Playlist',
              description: 'Add songs to this playlist to listen to them here.',
            ),
          );
        }

        final isSmart = playlist.id.startsWith('smart_');

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(audioPlayerServiceProvider)
                              .playQueue(songs, startIndex: 0);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play All'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          final shuffled = List<Song>.from(songs)..shuffle();
                          ref
                              .read(audioPlayerServiceProvider)
                              .playQueue(shuffled, startIndex: 0);
                        },
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Shuffle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSmart)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return SongListTile(
                    song: song,
                    onTap: () {
                      if (context.mounted) {
                        ref
                            .read(audioPlayerServiceProvider)
                            .playQueue(songs, startIndex: index);
                      }
                    },
                  );
                }, childCount: songs.length),
              )
            else
              SliverReorderableList(
                itemCount: songs.length,
                onReorder: (oldIndex, newIndex) {
                  ref
                      .read(playlistRepositoryProvider)
                      .reorderSongs(playlist.id, oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(
                      '${song.id}_$index',
                    ), // Need unique key for reorderable
                    index: index,
                    child: SongListTile(
                      song: song,
                      onTap: () {
                        if (context.mounted) {
                          ref
                              .read(audioPlayerServiceProvider)
                              .playQueue(songs, startIndex: index);
                        }
                      },
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (val) {
                          if (val == 'remove') {
                            ref
                                .read(playlistRepositoryProvider)
                                .removeSong(playlist.id, song.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove from playlist'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) =>
          SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Playlist Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
            onFieldSubmitted: (value) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != playlist.name) {
      await ref
          .read(playlistRepositoryProvider)
          .renamePlaylist(playlist.id, result);
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This will not delete the actual songs from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(playlistRepositoryProvider).deletePlaylist(playlist.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
