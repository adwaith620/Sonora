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

    final Widget child = artworkPath != null
        ? Image.file(
            File(artworkPath!),
            key: ValueKey(artworkPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(theme),
          )
        : _placeholder(theme);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      key: const ValueKey('placeholder'),
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        icon ?? Icons.music_note_rounded,
        size: iconSize ?? size * 0.4,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
