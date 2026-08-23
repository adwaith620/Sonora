import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../data/mock_data.dart';
import '../../data/providers/audio_provider.dart';
import '../../theme/dimensions.dart';
import '../common/song_list_tile.dart';

/// Songs screen — displays all songs in the library.
class SongsScreen extends ConsumerWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioService = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {},
            tooltip: 'Sort',
          ),
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  mockSongs.length.plural('song'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final shuffled = List.of(mockSongs)..shuffle();
                    audioService.playQueue(shuffled);
                    audioService
                        .toggleShuffle(); // Sync shuffle state internally
                  },
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
          ),
          // Song list
          Expanded(
            child: ListView.builder(
              itemCount: mockSongs.length,
              itemBuilder: (context, index) {
                return SongListTile(
                  song: mockSongs[index],
                  onTap: () {
                    audioService.playQueue(mockSongs, startIndex: index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
