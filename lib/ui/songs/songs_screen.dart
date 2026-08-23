import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';

final songsListProvider = FutureProvider<List<Song>>((ref) async {
  final db = ref.watch(libraryRepositoryProvider);
  return db.getAllSongs();
});

class SongsScreen extends ConsumerWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final songsAsync = ref.watch(songsListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Songs'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),

          songsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No music found. Add a folder in Settings.'),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(
                  bottom: kMiniPlayerHeight + Spacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        child: Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                audioService.playQueue(songs);
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play All'),
                            ),
                            const SizedBox(width: Spacing.sm),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                audioService.playQueue(songs);
                                audioService.toggleShuffle();
                              },
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('Shuffle'),
                            ),
                          ],
                        ),
                      );
                    }

                    final song = songs[index - 1];
                    return ListTile(
                      leading: ArtworkWidget(
                        artworkPath: song.artworkPath,
                        size: kArtworkThumbnailSize,
                        borderRadius: BorderRadius.circular(Spacing.xs),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {},
                      ),
                      onTap: () {
                        audioService.playQueue(songs, startIndex: index - 1);
                      },
                    );
                  }, childCount: songs.length + 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
