/// Riverpod providers for theme state management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

/// Provider for the current theme mode.
final themeModeProvider = StateProvider<SonoraThemeMode>(
  (ref) => SonoraThemeMode.system,
);

/// Provider for the seed color (used when dynamic colors unavailable).
final seedColorProvider = StateProvider<Color>((ref) => kDefaultSeedColor);

/// Provider for the album artwork color (used for dynamic theming in Now Playing).
final artworkColorProvider = StateProvider<Color?>((ref) => null);
