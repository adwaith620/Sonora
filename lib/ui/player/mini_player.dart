import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/audio_provider.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';
import 'now_playing_screen.dart';

/// Persistent mini player widget.
///
/// Displays a floating pill-shaped bar with artwork, song info,
/// play/pause and next controls, and a thin progress indicator.
/// Tapping opens the full Now Playing screen.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Only rebuild the entire MiniPlayer when the current song changes.
    final song = ref.watch(playbackStateProvider.select((s) => s.currentSong));

    if (song == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _openNowPlaying(context),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Radii.medium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.sm,
                Spacing.sm,
                Spacing.xs,
                Spacing.sm,
              ),
              child: Row(
                children: [
                  // Artwork
                  ArtworkWidget(
                    artworkPath: song.artworkPath,
                    size: 44,
                    borderRadius: BorderRadius.circular(Radii.small),
                  ),

                  const SizedBox(width: Spacing.md),

                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Play/Pause
                  Consumer(
                    builder: (context, ref, child) {
                      final isPlaying = ref.watch(
                        playbackStateProvider.select((s) => s.isPlaying),
                      );
                      final audio = ref.read(audioPlayerServiceProvider);
                      return IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: () => audio.togglePlayPause(),
                      );
                    },
                  ),

                  // Next
                  Consumer(
                    builder: (context, ref, child) {
                      final audio = ref.read(audioPlayerServiceProvider);
                      return IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: () => audio.next(),
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Progress bar
            Consumer(
              builder: (context, ref, child) {
                final progress = ref.watch(
                  playbackStateProvider.select((s) => s.progress),
                );
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
