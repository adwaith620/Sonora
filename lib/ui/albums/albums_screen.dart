import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/dimensions.dart';
import '../common/album_grid_tile.dart';

/// Albums screen — grid of all albums in the library.
class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {},
            tooltip: 'Sort',
          ),
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid: 2 cols on phone, 3 on tablet, 4-5 on desktop
          final crossAxisCount = constraints.maxWidth < 600
              ? 2
              : constraints.maxWidth < 900
              ? 3
              : constraints.maxWidth < 1200
              ? 4
              : 5;

          return GridView.builder(
            padding: const EdgeInsets.all(Spacing.sm),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: Spacing.xs,
              mainAxisSpacing: Spacing.xs,
            ),
            itemCount: mockAlbums.length,
            itemBuilder: (context, index) {
              return AlbumGridTile(album: mockAlbums[index], onTap: () {});
            },
          );
        },
      ),
    );
  }
}
