# Sonora

**Your music, locally.**

A cross-platform offline music player for Android and Windows, built with Flutter and Material 3.

> 🚧 **Work in Progress** — Sonora is under active development.

## Features

- 🎵 **Local Music Playback** — Play MP3, FLAC, WAV, M4A/AAC, and OGG files from your device
- 📱 **Cross-Platform** — Android and Windows desktop from a single codebase
- 🎨 **Material 3 Design** — Dynamic colors, light/dark/OLED themes, adaptive layouts
- 📚 **Library Management** — Browse by songs, albums, artists, playlists, and folders
- 🔍 **Global Search** — Search across your entire music library
- 🎛️ **Full Player Controls** — Shuffle, repeat, queue management, favorites
- 📻 **Mini Player** — Persistent playback controls while browsing
- 🖥️ **Adaptive Navigation** — Bottom nav on phones, navigation rail on tablets/desktop

## Screenshots

*Coming soon*

## Architecture

Sonora uses a clean, layered architecture:

```
lib/
├── core/           # Constants, extensions, utilities
├── data/
│   ├── models/     # Song, Album, Artist, Playlist models
│   └── database/   # Drift SQLite database (coming soon)
├── services/       # Audio player, library scanner, playlist service
├── theme/          # Material 3 theme system
├── navigation/     # GoRouter + adaptive navigation shell
└── ui/
    ├── common/     # Shared widgets (artwork, song tile, etc.)
    ├── home/       # Home screen with carousels
    ├── songs/      # Song list with sorting
    ├── albums/     # Album grid + detail view
    ├── artists/    # Artist list + detail view
    ├── playlists/  # Playlist management
    ├── folders/    # Folder browser
    ├── favorites/  # Favorites collection
    ├── player/     # Now Playing + Mini Player
    ├── search/     # Global search
    ├── settings/   # App settings
    └── visualizer/ # Audio visualizer (coming soon)
```

### Tech Stack

| Layer | Technology |
|:---|:---|
| **Framework** | Flutter 3.47+ |
| **Language** | Dart 3.13+ |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Database** | Drift (SQLite) — *coming soon* |
| **Audio Engine** | media_kit (libmpv) — *coming soon* |
| **Metadata** | metadata_god (Rust/lofty) — *coming soon* |
| **Theming** | Material 3 + dynamic_color |

## Getting Started

### Prerequisites

- Flutter 3.47 or later
- Android SDK (for Android builds)
- Visual Studio with C++ Desktop workload (for Windows builds)

### Development

```bash
# Clone the repository
git clone https://github.com/your-username/sonora.git
cd sonora

# Install dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on Windows
flutter run -d windows

# Run tests
flutter test
```

### Building

```bash
# Android APK
flutter build apk

# Windows
flutter build windows
```

## Roadmap

See [SONORA_ROADMAP.md](SONORA_ROADMAP.md) for detailed progress tracking.

- [x] Phase 1: Project scaffold + Material 3 design system + adaptive navigation
- [ ] Phase 2: Database schema + data layer
- [ ] Phase 3: Library scanner + metadata extraction
- [ ] Phase 4: Audio playback engine
- [ ] Phase 5: Mini player + Now Playing (functional)
- [ ] Phase 6: Home screen (data-driven)
- [ ] Phase 7: Playlists + Favorites
- [ ] Phase 8: Search
- [ ] Phase 9: Audio visualizer
- [ ] Phase 10: Android media controls
- [ ] Phase 11: Windows integration
- [ ] Phase 12: Testing
- [ ] Phase 13: Performance optimization
- [ ] Phase 14: UI polish
- [ ] Phase 15: Documentation + release

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.
