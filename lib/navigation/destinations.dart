import 'package:flutter/material.dart';

/// Primary navigation destinations for Sonora.
enum SonoraDestination {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  songs(
    label: 'Songs',
    icon: Icons.music_note_outlined,
    selectedIcon: Icons.music_note_rounded,
  ),
  albums(
    label: 'Albums',
    icon: Icons.album_outlined,
    selectedIcon: Icons.album_rounded,
  ),
  artists(
    label: 'Artists',
    icon: Icons.person_outlined,
    selectedIcon: Icons.person_rounded,
  ),
  playlists(
    label: 'Playlists',
    icon: Icons.queue_music_outlined,
    selectedIcon: Icons.queue_music_rounded,
  );

  const SonoraDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Convert to [NavigationDestination] for bottom nav bar.
  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: label,
    );
  }

  /// Convert to [NavigationRailDestination] for navigation rail.
  NavigationRailDestination toNavigationRailDestination() {
    return NavigationRailDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      label: Text(label),
    );
  }
}
