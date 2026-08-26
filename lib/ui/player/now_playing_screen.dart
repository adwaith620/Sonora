import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../services/audio_player_service.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';
import 'audio_visualizer_widget.dart';
import 'queue_bottom_sheet.dart';

/// Now Playing screen — the full-screen music player.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

    final currentSong = ref.watch(
      playbackStateProvider.select((s) => s.currentSong),
    );

    if (currentSong == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(context, currentSong),

              // Main content
              Expanded(
                child: isCompact
                    ? _buildCompactLayout(context, currentSong, ref)
                    : _buildWideLayout(context, currentSong, ref),
              ),

              // Bottom actions
              if (isCompact) _buildBottomActions(context),

              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Song currentSong) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'PLAYING FROM',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  currentSong.album,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    Song currentSong,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Album artwork
          _buildArtwork(context, currentSong, 280),

          // Visualizer
          const SizedBox(height: Spacing.xl),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: AudioVisualizerWidget(height: 32),
          ),

          const Spacer(flex: 1),
          // Song info
          _buildSongInfo(context, currentSong, ref),
          const SizedBox(height: Spacing.xl),
          // Progress bar
          _buildProgressBar(context),
          const SizedBox(height: Spacing.lg),
          // Playback controls
          _buildPlaybackControls(context),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    Song currentSong,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        // Left: artwork
        Expanded(
          child: Center(child: _buildArtwork(context, currentSong, 360)),
        ),
        // Right: controls
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSongInfo(context, currentSong, ref),

                const SizedBox(height: Spacing.xl),
                const AudioVisualizerWidget(height: 32),

                const SizedBox(height: Spacing.xl),
                _buildProgressBar(context),
                const SizedBox(height: Spacing.xl),
                _buildPlaybackControls(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtwork(
    BuildContext context,
    Song currentSong,
    double artworkSize,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.extraLarge),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: ArtworkWidget(
        artworkPath: currentSong.artworkPath,
        size: artworkSize,
        borderRadius: BorderRadius.circular(Radii.extraLarge),
        icon: Icons.music_note_rounded,
        iconSize: 80,
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song currentSong, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = currentSong.isFavorite;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentSong.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '${currentSong.artist} • ${currentSong.album}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? theme.colorScheme.primary : null,
          ),
          onPressed: () => _toggleFavorite(ref, currentSong),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, Song song) async {
    final newFavorite = !song.isFavorite;

    // 1. Immediately update in-memory state for instant UI feedback
    ref
        .read(playbackStateNotifierProvider.notifier)
        .updateCurrentSongFavorite(newFavorite);

    // 2. Persist to database (fire-and-forget with error handling)
    try {
      await ref.read(libraryRepositoryProvider).toggleFavorite(song.id);
    } catch (_) {
      // Revert the in-memory state if the DB write failed
      ref
          .read(playbackStateNotifierProvider.notifier)
          .updateCurrentSongFavorite(song.isFavorite);
    }
  }

  Widget _buildProgressBar(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        final state = ref.watch(playbackStateProvider);
        final progress = state.progress;
        final elapsed = state.position;
        final remaining = state.duration - state.position;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: progress,
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * state.duration.inMilliseconds)
                        .round(),
                  );
                  ref.read(audioPlayerServiceProvider).seek(newPosition);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    elapsed.toPlaybackString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    remaining.toRemainingString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        final state = ref.watch(playbackStateProvider);
        final audio = ref.read(audioPlayerServiceProvider);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                color: state.shuffleEnabled ? theme.colorScheme.primary : null,
              ),
              onPressed: () => audio.toggleShuffle(),
            ),

            // Previous
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 36),
              onPressed: () => audio.previous(),
            ),

            // Play/Pause
            FilledButton(
              onPressed: () => audio.togglePlayPause(),
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 36,
              ),
            ),

            // Next
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 36),
              onPressed: () => audio.next(),
            ),

            // Repeat
            IconButton(
              icon: Icon(
                state.repeatMode == SonoraRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: state.repeatMode != SonoraRepeatMode.off
                    ? theme.colorScheme.primary
                    : null,
              ),
              onPressed: () => audio.cycleRepeatMode(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => const FractionallySizedBox(
                  heightFactor: 0.85,
                  child: QueueBottomSheet(),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
    );
  }
}
