# Sonora

**Your music, locally.**

A cross-platform offline music player for Android and Windows, built with Flutter and Material 3.

## Features

- **Local Music Playback** — Play MP3, FLAC, WAV, M4A/AAC, and OGG files from your device.
- **Cross-Platform** — Android and Windows desktop from a single codebase.
- **Material 3 Design** — Dynamic colors, light/dark themes, fluid animations, and adaptive layouts.
- **Library Management** — Fast recursive scanning, metadata extraction, artwork caching, and smart sorting.
- **Global Search** — Instant local full-text search across songs, artists, and albums with search history.
- **Playlists & Favorites** — Create custom playlists, favorite tracks, and track recently played/added items.
- **Queue Management** — Real-time queue, shuffle, repeat modes, and gapless-ready playback state.
- **Audio Visualizer** — Native Android FFT-based audio visualizer synchronized with real-time playback.
- **System Integration** — Android MediaSession (background playback, lock screen controls) and Windows SMTC (hardware media keys, taskbar controls).
- **Performance Optimized** — Drift SQLite backend, efficient Riverpod state management, and optimized artwork rendering for large libraries.

## Screenshots

*(Screenshots can be placed here)*

## Architecture

Sonora uses a clean, layered architecture leveraging:
- **Flutter** & **Dart 3**
- **Riverpod** for robust, testable state management
- **Drift (SQLite)** for fast local data persistence
- **media_kit** (libmpv) for rock-solid cross-platform audio playback
- **audio_service** & **Windows SMTC** for native OS media integrations

For detailed architectural decisions and component breakdowns, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.22+ recommended)
- Android SDK (for Android builds)
- Visual Studio with C++ Desktop workload (for Windows builds)

### Development

```bash
# Clone the repository
git clone https://github.com/adwaith620/Sonora.git
cd Sonora

# Install dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on Windows
flutter run -d windows

# Run all tests (Unit, Widget, Integration)
flutter test
```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```
*Note: The APK will be output to `build/app/outputs/flutter-apk/app-release.apk`.*

**Windows Desktop:**
```bash
flutter build windows --release
```
*Note: The Windows executable will be output to `build/windows/x64/runner/Release/sonora.exe`.*

## Project Phases

This project was developed iteratively in 15 distinct phases. See [SONORA_ROADMAP.md](SONORA_ROADMAP.md) for a historical tracking of the milestones.

- Phase 1: Material 3 UI Foundation
- Phase 2: Drift SQLite Database
- Phase 3: Real Audio Engine (`media_kit` + `audio_service`)
- Phase 4: Local Library Scanner & Metadata (`audio_metadata_reader`)
- Phase 5: Player UI Integration
- Phase 6: Home Screen + Library UI
- Phase 7: Playlists + Favorites
- Phase 8: Search
- Phase 9: Audio Visualizer
- Phase 10: Android Platform Integration
- Phase 11: Windows Platform Integration
- Phase 12: Comprehensive Testing
- Phase 13: Performance Optimization
- Phase 14: UI Polish & Animations
- Phase 15: Final Documentation and Build

## License

MIT License — see [LICENSE](LICENSE) for details.
