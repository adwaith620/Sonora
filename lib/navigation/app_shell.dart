import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../ui/player/mini_player.dart';
import 'destinations.dart';

/// Adaptive navigation shell for Sonora.
///
/// Uses a bottom navigation bar on compact screens (phones) and
/// a navigation rail on medium/expanded screens (tablets, desktop).
/// The mini player floats between content and navigation.
class AppShell extends StatefulWidget {
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useNavRail = width >= kCompactBreakpoint;

    if (useNavRail) {
      return _buildNavRailLayout(context);
    } else {
      return _buildBottomNavLayout(context);
    }
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
