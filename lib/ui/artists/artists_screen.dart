import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';

import '../../data/models/artist.dart';
import '../../data/providers/repository_providers.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';

final artistsListProvider = FutureProvider<List<Artist>>((ref) async {
  final db = ref.watch(libraryRepositoryProvider);
  return db.getAllArtists();
});

class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: artistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (artists) {
          if (artists.isEmpty) {
            return const Center(child: Text('No artists found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: kMiniPlayerHeight + Spacing.md,
            ),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return ListTile(
                leading: ArtworkWidget(
                  artworkPath: artist.artworkPath,
                  size: 48,
                  borderRadius: BorderRadius.circular(24),
                  icon: Icons.person_rounded,
                ),
                title: Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
