import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/song_list_tile.dart';

final favoriteSongsProvider = StreamProvider<List<Song>>((ref) {
  final db = ref.watch(libraryRepositoryProvider);
  return db.watchFavorites();
});

/// Favorites screen — shows favorite songs from the Drift database.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final favoritesAsync = ref.watch(favoriteSongsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'No favorites yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Tap the heart icon on any song to add it here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Action bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      '${favorites.length} song${favorites.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        audioService.playQueue(favorites);
                        audioService.toggleShuffle();
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: const Text('Shuffle'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: kMiniPlayerHeight + Spacing.md,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    return SongListTile(
                      song: favorites[index],
                      onTap: () {
                        audioService.playQueue(favorites, startIndex: index);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
