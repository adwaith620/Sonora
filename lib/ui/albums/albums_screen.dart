import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/models/album.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';

final albumsListProvider = FutureProvider<List<Album>>((ref) async {
  final db = ref.watch(libraryRepositoryProvider);
  return db.getAllAlbums();
});

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (albums) {
          if (albums.isEmpty) {
            return const Center(child: Text('No albums found.'));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 600
                  ? 2
                  : constraints.maxWidth < 900
                  ? 3
                  : constraints.maxWidth < 1200
                  ? 4
                  : 5;

              return GridView.builder(
                padding: const EdgeInsets.all(Spacing.sm)
                    .copyWith(bottom: kMiniPlayerHeight + Spacing.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: Spacing.xs,
                  mainAxisSpacing: Spacing.xs,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  return AlbumGridTile(album: albums[index], onTap: () {});
                },
              );
            },
          );
        },
      ),
    );
  }
}
