import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/dimensions.dart';

/// Reusable artwork display widget.
///
/// Shows the artwork from a file path, or a placeholder with a music note
/// icon when no artwork is available.
class ArtworkWidget extends StatelessWidget {
  const ArtworkWidget({
    super.key,
    this.artworkPath,
    this.size = 56.0,
    this.borderRadius,
    this.icon,
    this.iconSize,
  });

  /// Path to the artwork file on disk.
  final String? artworkPath;

  /// Size of the artwork (width and height).
  final double size;

  /// Border radius. Defaults to [Radii.small] for small sizes,
  /// [Radii.medium] for medium, [Radii.large] for large.
  final BorderRadius? borderRadius;

  /// Icon to show in the placeholder. Defaults to music note.
  final IconData? icon;

  /// Size of the placeholder icon.
  final double? iconSize;

  BorderRadius get _effectiveBorderRadius {
    if (borderRadius != null) return borderRadius!;
    if (size <= 56) return BorderRadius.circular(Radii.small);
    if (size <= 160) return BorderRadius.circular(Radii.medium);
    return BorderRadius.circular(Radii.large);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = _effectiveBorderRadius;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: artworkPath != null && File(artworkPath!).existsSync()
            ? Image.file(
                File(artworkPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _placeholder(theme),
              )
            : _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        icon ?? Icons.music_note_rounded,
        size: iconSize ?? size * 0.4,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
