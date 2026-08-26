import 'package:flutter/material.dart';

import '../../data/models/album.dart';
import '../../theme/dimensions.dart';
import 'artwork_widget.dart';

/// Album grid tile for the album browser.
///
/// Shows artwork, album name, artist, and year in a compact card.
class AlbumGridTile extends StatelessWidget {
  const AlbumGridTile({super.key, required this.album, this.onTap});

  final Album album;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.medium),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album artwork
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'album_artwork_${album.id}',
                child: ArtworkWidget(
                  artworkPath: album.artworkPath,
                  size: double.infinity,
                  borderRadius: BorderRadius.circular(Radii.medium),
                  icon: Icons.album_rounded,
                ),
              ),
            ),

            const SizedBox(height: Spacing.sm),

            // Album title
            Text(
              album.name,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Artist and year
            Text(
              album.year != null
                  ? '${album.artist} • ${album.year}'
                  : album.artist,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
