/// Dart extension methods used throughout Sonora.
library;

/// Extension on [Duration] for display formatting.
extension DurationFormatting on Duration {
  /// Formats duration as `m:ss` or `h:mm:ss`.
  String toPlaybackString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats as remaining time `-m:ss`.
  String toRemainingString() => '-${toPlaybackString()}';
}

/// Extension on [String] for music metadata helpers.
extension StringMusic on String {
  /// Returns the string or a default 'Unknown' value.
  String orUnknown([String fallback = 'Unknown']) =>
      trim().isEmpty ? fallback : this;

  /// Returns the string or 'Unknown Artist'.
  String orUnknownArtist() => orUnknown('Unknown Artist');

  /// Returns the string or 'Unknown Album'.
  String orUnknownAlbum() => orUnknown('Unknown Album');
}

/// Extension on [int] for pluralization.
extension IntPlural on int {
  /// Returns singular or plural form.
  String plural(String singular, [String? plural]) {
    final p = plural ?? '${singular}s';
    return '$this ${this == 1 ? singular : p}';
  }
}
