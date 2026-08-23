/// Spacing, radii, and dimension constants following an 8dp grid.
library;

/// Spacing constants based on Material 3 8dp grid.
abstract final class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

/// Corner radius constants inspired by OpenTune's M3 design.
abstract final class Radii {
  /// Small radius for thumbnails, badges.
  static const double small = 8.0;

  /// Medium radius for cards, dialogs.
  static const double medium = 16.0;

  /// Large radius for album artwork, bottom sheets.
  static const double large = 24.0;

  /// Extra large for Now Playing artwork.
  static const double extraLarge = 28.0;

  /// Full pill shape for mini player, nav bar, chips.
  static const double pill = 999.0;
}

/// Elevation levels following Material 3.
abstract final class Elevations {
  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;
}
