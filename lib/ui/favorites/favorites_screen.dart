import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/dimensions.dart';
import '../common/song_list_tile.dart';

/// Favorites screen — shows favorite songs.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = mockSongs.where((s) => s.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Column(
        children: [
          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return SongListTile(song: favorites[index], onTap: () {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
