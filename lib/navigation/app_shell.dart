import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/audio_provider.dart';

import '../core/constants.dart';
import '../core/platform_utils.dart';

import 'package:window_manager/window_manager.dart';

import '../ui/player/mini_player.dart';
import 'destinations.dart';

/// Adaptive navigation shell for Sonora.
///
/// Uses a bottom navigation bar on compact screens (phones) and
/// a navigation rail on medium/expanded screens (tablets, desktop).
/// The mini player floats between content and navigation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useNavRail = width >= kCompactBreakpoint;

    Widget layout;
    if (useNavRail) {
      layout = _buildNavRailLayout(context);
    } else {
      layout = _buildBottomNavLayout(context);
    }

    Widget child = layout;
    if (isDesktop) {
      final theme = Theme.of(context);
      child = Column(
        children: [
          WindowCaption(
            brightness: theme.brightness,
            title: const Text(kAppName),
            backgroundColor: theme.colorScheme.surface,
          ),
          Expanded(child: layout),
        ],
      );
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.space): const PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const SeekForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const SeekBackwardIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (intent) => _togglePlayPause(),
          ),
          SeekForwardIntent: CallbackAction<SeekForwardIntent>(
            onInvoke: (intent) => _seek(const Duration(seconds: 5)),
          ),
          SeekBackwardIntent: CallbackAction<SeekBackwardIntent>(
            onInvoke: (intent) => _seek(const Duration(seconds: -5)),
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  void _togglePlayPause() {
    final audioService = ref.read(audioPlayerServiceProvider);
    final state = ref.read(playbackStateProvider);
    if (state.isPlaying) {
      audioService.pause();
    } else {
      audioService.resume();
    }
  }

  void _seek(Duration offset) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final state = ref.read(playbackStateProvider);
    audioService.seek(state.position + offset);
  }

  Widget _buildBottomNavLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.child),
          // Mini player above navigation
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: SonoraDestination.values
            .map((d) => d.toNavigationDestination())
            .toList(),
      ),
    );
  }

  Widget _buildNavRailLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Navigation rail
          NavigationRail(
            selectedIndex: widget.currentIndex,
            onDestinationSelected: widget.onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                Icons.music_note_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            destinations: SonoraDestination.values
                .map((d) => d.toNavigationRailDestination())
                .toList(),
          ),
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          // Content area
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.child),
                // Mini player
                const MiniPlayer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class SeekForwardIntent extends Intent {
  const SeekForwardIntent();
}

class SeekBackwardIntent extends Intent {
  const SeekBackwardIntent();
}
