import 'package:flutter/material.dart';

import '../../core/extensions.dart';
import '../../data/models/song.dart';
import '../../theme/dimensions.dart';
import 'artwork_widget.dart';
import 'song_context_menu.dart';

/// A compact song list tile inspired by OpenTune's song item.
///
/// Shows artwork thumbnail, title, artist • album, and duration.
class SongListTile extends StatelessWidget {
  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.showTrackNumber = false,
    this.isPlaying = false,
  });

  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showTrackNumber;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = isPlaying
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(Radii.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            // Leading: track number or artwork
            if (showTrackNumber)
              SizedBox(
                width: 32,
                child: Text(
                  '${song.trackNumber ?? '-'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ArtworkWidget(artworkPath: song.artworkPath, size: 48),

            const SizedBox(width: Spacing.md),

            // Center: title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: titleColor,
                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.artist} • ${song.album}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: Spacing.sm),

            // Duration
            Text(
              song.duration.toPlaybackString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Trailing action
            if (trailing != null) ...[
              const SizedBox(width: Spacing.xs),
              trailing!,
            ] else ...[
              const SizedBox(width: Spacing.xs),
              SongContextMenu(song: song),
            ],
          ],
        ),
      ),
    );
  }
}
