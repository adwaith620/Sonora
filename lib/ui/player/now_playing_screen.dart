import 'package:flutter/material.dart';

import '../../core/extensions.dart';
import '../../data/mock_data.dart';
import '../../data/models/song.dart';
import '../../services/audio_player_service.dart';
import '../../theme/dimensions.dart';
import '../common/artwork_widget.dart';

/// Now Playing screen — the full-screen music player.
///
/// Designed as a modal bottom sheet that slides up from the mini player.
/// Visually inspired by OpenTune's immersive player with large artwork,
/// clean controls, and dynamic theming.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  // Mock playback state for Phase 1
  double _progress = 0.35;
  bool _isPlaying = true;
  bool _isFavorite = true;
  bool _shuffleEnabled = false;
  SonoraRepeatMode _repeatMode = SonoraRepeatMode.off;

  Song get _currentSong => mockCurrentSong;

  Duration get _elapsed => Duration(
    milliseconds: (_progress * _currentSong.duration.inMilliseconds).round(),
  );

  Duration get _remaining => _currentSong.duration - _elapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

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
              _buildTopBar(context),

              // Main content
              Expanded(
                child: isCompact
                    ? _buildCompactLayout(context)
                    : _buildWideLayout(context),
              ),

              // Bottom actions
              _buildBottomActions(context),

              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
                  _currentSong.album,
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

  Widget _buildCompactLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Album artwork
          _buildArtwork(context, 280),
          const Spacer(flex: 1),
          // Song info
          _buildSongInfo(context),
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

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        // Left: artwork
        Expanded(child: Center(child: _buildArtwork(context, 360))),
        // Right: controls
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSongInfo(context),
                const SizedBox(height: Spacing.xxl),
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

  Widget _buildArtwork(BuildContext context, double artworkSize) {
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
        artworkPath: _currentSong.artworkPath,
        size: artworkSize,
        borderRadius: BorderRadius.circular(Radii.extraLarge),
        icon: Icons.music_note_rounded,
        iconSize: 80,
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentSong.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '${_currentSong.artist} • ${_currentSong.album}',
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
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorite ? theme.colorScheme.primary : null,
          ),
          onPressed: () => setState(() => _isFavorite = !_isFavorite),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _progress,
            onChanged: (value) => setState(() => _progress = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _elapsed.toPlaybackString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _remaining.toRemainingString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: _shuffleEnabled ? theme.colorScheme.primary : null,
          ),
          onPressed: () => setState(() => _shuffleEnabled = !_shuffleEnabled),
        ),

        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 36),
          onPressed: () {},
        ),

        // Play/Pause
        FilledButton(
          onPressed: () => setState(() => _isPlaying = !_isPlaying),
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 36,
          ),
        ),

        // Next
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 36),
          onPressed: () {},
        ),

        // Repeat
        IconButton(
          icon: Icon(
            _repeatMode == SonoraRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: _repeatMode != SonoraRepeatMode.off
                ? theme.colorScheme.primary
                : null,
          ),
          onPressed: () {
            setState(() {
              _repeatMode =
                  SonoraRepeatMode.values[(_repeatMode.index + 1) %
                      SonoraRepeatMode.values.length];
            });
          },
        ),
      ],
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
            onPressed: () {},
            tooltip: 'Queue',
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            onPressed: () {},
            tooltip: 'Add to Playlist',
          ),
        ],
      ),
    );
  }
}
