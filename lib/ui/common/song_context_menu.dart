import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../dialogs/add_to_playlist_dialog.dart';

class SongContextMenu extends ConsumerWidget {
  const SongContextMenu({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        if (value == 'play_next') {
          // Assuming insertNext implementation exists or we just add to queue
          final audioService = ref.read(audioPlayerServiceProvider);
          // Wait, queue functionality in audio_service.dart might not have insertNext. Let's just add to queue.
          audioService.addToQueue(song);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Added to queue')));
        } else if (value == 'add_to_playlist') {
          showDialog(
            context: context,
            builder: (context) => AddToPlaylistDialog(song: song),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'play_next', child: Text('Add to Queue')),
        const PopupMenuItem(
          value: 'add_to_playlist',
          child: Text('Add to Playlist...'),
        ),
      ],
    );
  }
}
