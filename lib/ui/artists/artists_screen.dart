import 'package:flutter/material.dart';

import '../../core/extensions.dart';
import '../../data/mock_data.dart';
import '../common/artwork_widget.dart';

/// Artists screen — list of all artists in the library.
class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: mockArtists.length,
        itemBuilder: (context, index) {
          final artist = mockArtists[index];
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
            subtitle: Text(
              '${artist.songCount.plural('song')} • ${artist.albumCount.plural('album')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          );
        },
      ),
    );
  }
}
