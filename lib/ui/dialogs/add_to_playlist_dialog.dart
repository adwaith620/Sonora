import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../data/models/song.dart';
import '../../data/providers/playlist_providers.dart';
import '../../data/providers/repository_providers.dart';
import 'create_playlist_dialog.dart';

class AddToPlaylistDialog extends ConsumerWidget {
  const AddToPlaylistDialog({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPlaylistsAsync = ref.watch(userPlaylistsProvider);

    return AlertDialog(
      title: const Text('Add to Playlist'),
      contentPadding: const EdgeInsets.only(top: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: userPlaylistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('You have no playlists.'),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(playlist.name),
                  subtitle: Text(playlist.songCount.plural('song')),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await ref
                          .read(playlistRepositoryProvider)
                          .addSong(playlist.id, song.id);
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('Added to ${playlist.name}')),
                      );
                    } catch (e) {
                      nav.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to add: $e')),
                      );
                    }
                  },
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error: $e'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CreatePlaylistDialog(),
            );
          },
          child: const Text('New Playlist'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
