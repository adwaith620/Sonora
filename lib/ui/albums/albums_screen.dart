import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/constants.dart';
import '../../data/models/album.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/sort_providers.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';

final albumsListProvider = FutureProvider<List<Album>>((ref) async {
  final db = ref.watch(libraryRepositoryProvider);
  final sort = ref.watch(albumsSortProvider);
  final albums = await db.getAllAlbums();

  switch (sort) {
    case AlbumSortField.title:
      albums.sort((a, b) => a.name.compareTo(b.name));
      break;
    case AlbumSortField.artist:
      albums.sort((a, b) => a.artist.compareTo(b.artist));
      break;
    case AlbumSortField.year:
      albums.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      break;
  }
  return albums;
});

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsListProvider);
    final currentSort = ref.watch(albumsSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          PopupMenuButton<AlbumSortField>(
            icon: const Icon(Icons.sort_rounded),
            initialValue: currentSort,
            onSelected: (sort) {
              ref.read(albumsSortProvider.notifier).state = sort;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AlbumSortField.title,
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem(
                value: AlbumSortField.artist,
                child: Text('Sort by Artist'),
              ),
              const PopupMenuItem(
                value: AlbumSortField.year,
                child: Text('Sort by Year'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
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

              return AnimationLimiter(
                child: GridView.builder(
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
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: crossAxisCount,
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: AlbumGridTile(
                            album: albums[index],
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/album',
                                arguments: albums[index].id,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
