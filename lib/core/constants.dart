/// App-wide constants for Sonora.
library;

/// Supported audio file extensions.
const Set<String> kSupportedAudioExtensions = {
  '.mp3',
  '.flac',
  '.wav',
  '.m4a',
  '.aac',
  '.ogg',
};

/// App metadata.
const String kAppName = 'Sonora';
const String kAppTagline = 'Your music, locally.';
const String kAppVersion = '0.1.0';

/// Artwork dimensions.
const double kArtworkThumbnailSize = 56.0;
const double kArtworkGridSize = 160.0;
const double kArtworkDetailSize = 280.0;
const double kArtworkNowPlayingSize = 320.0;

/// Layout breakpoints.
const double kCompactBreakpoint = 600.0;
const double kMediumBreakpoint = 840.0;
const double kExpandedBreakpoint = 1200.0;

/// Mini player.
const double kMiniPlayerHeight = 64.0;
const double kMiniPlayerArtworkSize = 48.0;
const double kMiniPlayerProgressHeight = 2.0;

/// Navigation.
const double kNavigationBarHeight = 80.0;
const double kNavigationRailWidth = 80.0;
const double kNavigationRailExpandedWidth = 256.0;
