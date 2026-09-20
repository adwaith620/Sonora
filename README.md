<div align="center">

# 🎵 Sonora

### Your music, locally.

A fast, beautiful, fully offline music player for Android and Windows, built with Flutter and Material 3.

</div>

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Screenshots](#screenshots)
- [Download](#download)
- [Supported Formats](#supported-formats)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Building for Release](#building-for-release)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Development Roadmap](#development-roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## About

Sonora is a local-first music player. There are no accounts, no streaming, and no internet connection required: it plays the music already on your device and makes it easy to browse, search, and organize. A single Flutter codebase powers both the Android app and the Windows desktop app, with native media integrations on each platform (lock screen controls on Android, hardware media keys and taskbar controls on Windows).

---

## Features

### Playback
- Local music playback for MP3, FLAC, WAV, M4A/AAC, and OGG files
- Queue management with a real-time queue, shuffle, and repeat modes
- Gapless-ready playback state
- Background playback on Android with lock screen controls

### Library
- Fast recursive scanning of your music folders
- Metadata extraction for titles, artists, albums, and more
- Artwork caching so large libraries stay smooth
- Smart sorting across songs, artists, and albums

### Discovery & Organization
- **Global search:** instant local full-text search across songs, artists, and albums, with search history
- **Playlists:** create custom playlists
- **Favorites:** mark tracks you love
- **Recently played / recently added** tracking

### Look & Feel
- Material 3 design with dynamic colors, light and dark themes, fluid animations, and adaptive layouts
- **Audio visualizer:** native Android FFT-based visualizer synced with real-time playback

### System Integration
- **Android:** MediaSession (background playback, lock screen and notification controls)
- **Windows:** System Media Transport Controls (SMTC) for hardware media keys and taskbar controls

### Performance
- Drift (SQLite) backend for fast queries on big libraries
- Riverpod for efficient, targeted UI rebuilds
- Optimized artwork rendering

---

## Screenshots

Add screenshots here. A suggested layout:
- Home
- Library
- Now Playing
- Search
- Playlists
- Windows

---

## Download

Prebuilt v1.0.0 binaries are included in the repository root:

| Platform | File |
| --- | --- |
| 🤖 Android | `Sonora-v1.0.0-Android.apk` |
| 🪟 Windows (x64) | `Sonora-v1.0.0-Windows-x64.zip` |

> **Android:** enable "Install unknown apps" for your browser or file manager, then open the APK.  
> **Windows:** extract the ZIP and run `sonora.exe`.

---

## Supported Formats

| Format | Extension(s) |
| --- | --- |
| MP3 | `.mp3` |
| FLAC | `.flac` |
| WAV | `.wav` |
| AAC / M4A | `.m4a`, `.aac` |
| Ogg Vorbis | `.ogg` |

---

## Tech Stack

| Area | Technology |
| --- | --- |
| Framework | [Flutter](https://flutter.dev/) & Dart 3 |
| State management | [Riverpod](https://riverpod.dev/) |
| Local database | [Drift](https://drift.simonbinder.eu/) (SQLite) |
| Audio engine | [media_kit](https://pub.dev/packages/media_kit) (libmpv) |
| OS media integration | [audio_service](https://pub.dev/packages/audio_service), Windows SMTC |
| Metadata | [audio_metadata_reader](https://pub.dev/packages/audio_metadata_reader) |
| Design system | Material 3 |

---

## Architecture

Sonora uses a clean, layered architecture:

```
┌────────────────────────────────────────┐
│ UI Layer (Flutter widgets, Material 3) │
├────────────────────────────────────────┤
│ State Layer (Riverpod providers)       │
├────────────────────────────────────────┤
│ Domain / Services                      │
│ (player, scanner, search, playlists)   │
├────────────────────────────────────────┤
│ Data Layer (Drift / SQLite)            │
├────────────────────────────────────────┤
│ Platform Layer                         │
│ (media_kit, MediaSession, SMTC, FFT)   │
└────────────────────────────────────────┘
```

For detailed architectural decisions and component breakdowns, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22 or newer
- Android builds: Android SDK (via Android Studio)
- Windows builds: Visual Studio with the "Desktop development with C++" workload

Verify your setup:
```bash
flutter doctor
```

### Run Locally

```bash
# Clone the repository
git clone https://github.com/adwaith620/Sonora.git
cd Sonora

# Install dependencies
flutter pub get

# Run on Android (device or emulator)
flutter run -d android

# Run on Windows
flutter run -d windows
```

---

## Building for Release

### Android APK

```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Windows Desktop

```bash
flutter build windows --release
```
Output: `build/windows/x64/runner/Release/sonora.exe`

---

## Testing

Run the full suite (unit, widget, and integration tests):

```bash
flutter test
```

---

## Project Structure

```
Sonora/
├── android/              # Android platform code (MediaSession, visualizer)
├── windows/              # Windows platform code (SMTC integration)
├── lib/                  # Main Dart application source
├── test/                 # Unit, widget, and integration tests
├── ARCHITECTURE.md       # Architecture decisions and component breakdown
├── SONORA_ROADMAP.md     # Phase-by-phase development history
├── implementation_plan.md# Original implementation plan
├── pubspec.yaml          # Dependencies and project config
└── LICENSE               # MIT License
```

---

## Development Roadmap

Sonora was built iteratively across 15 phases. See [SONORA_ROADMAP.md](SONORA_ROADMAP.md) for details.

- [x] Phase 1: Material 3 UI foundation
- [x] Phase 2: Drift SQLite database
- [x] Phase 3: Real audio engine (media_kit + audio_service)
- [x] Phase 4: Local library scanner & metadata
- [x] Phase 5: Player UI integration
- [x] Phase 6: Home screen + Library UI
- [x] Phase 7: Playlists + Favorites
- [x] Phase 8: Search
- [x] Phase 9: Audio visualizer
- [x] Phase 10: Android platform integration
- [x] Phase 11: Windows platform integration
- [x] Phase 12: Comprehensive testing
- [x] Phase 13: Performance optimization
- [x] Phase 14: UI polish & animations
- [x] Phase 15: Final documentation and build

---

## Contributing

Contributions, bug reports, and feature ideas are welcome.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please run `flutter test` and `flutter analyze` before submitting.

---

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">
Made with Flutter 💙
</div>
