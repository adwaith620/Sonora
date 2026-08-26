# Sonora Architecture

Sonora follows a strict layered architecture emphasizing cross-platform compatibility, testability, and deterministic UI state.

## Core Layers

### 1. Presentation Layer (UI)
- **Framework**: Flutter (Material 3).
- **Navigation**: `go_router` for robust routing with adaptive nested shells (bottom navigation for mobile, navigation rail for desktop).
- **Theme**: Managed by a dynamic `ThemeProvider` that builds `ThemeData` on the fly from system seed colors, supporting OLED black and light/dark modes.
- **Animations**: Utilizes `Hero` transitions for artwork, `flutter_staggered_animations` for smooth staggered list/grid rendering, and native haptic feedback for player controls.

### 2. State Management (Riverpod)
- The entire app is wired using `riverpod` (Provider pattern). 
- Providers inject all critical dependencies (`databaseProvider`, `audioPlayerServiceProvider`, `visualizerServiceProvider`).
- UI state is reactive. For example, `playbackStateProvider` updates precisely when the player state changes. Fine-grained rebuilds (using `select()`) ensure O(1) performance even for 60fps seek bar updates.

### 3. Data Layer & Local Database (Drift)
- **Database Engine**: Drift over SQLite, optimized with `sqlite3_flutter_libs` to run on Android and Windows seamlessly.
- **Schema**: Fully normalized schemas including `Songs`, `Albums`, `Artists`, `Playlists`, `PlaylistSongs`, and `SearchHistory`.
- **Query Optimization**: Background isolates and indices ensure smooth scrolling and instant global search results without locking the main thread.

### 4. Audio Engine (`media_kit`)
- Backed by **libmpv** via `media_kit`, guaranteeing vast codec support (FLAC, ALAC, MP3, WAV, OGG) without relying on disparate native player engines.
- `AudioPlayerService` acts as the abstraction layer, unifying the queue management, shuffle, repeat, and play/pause logic into predictable Dart streams.

### 5. Local Library Scanner
- **File Access**: On Android, leverages the Storage Access Framework (SAF) to securely browse user-selected trees without requiring invasive all-files access permissions. On Windows, uses direct file I/O.
- **Metadata Parser**: Uses the pure-Dart `audio_metadata_reader` package for ID3/Vorbis/MP4 parsing, extracting metadata and embedded artwork bytes.
- **Incremental Syncing**: Compares file paths, sizes, and modification dates to only parse new or changed tracks.
- **Artwork Caching**: Embedded artwork bytes are deduplicated by SHA-256 hash and saved locally, avoiding database blob bloat and ensuring lightning-fast list loading.

## Platform Integrations

### Android (`audio_service` & `Visualizer`)
- **Background Playback & Notifications**: Uses `audio_service` with a custom `BaseAudioHandler` to interface with Android's `MediaSession`. Ensures Sonora appears in the lock screen, notification shade, and responds to Bluetooth/headset events.
- **Audio Focus**: Automatically pauses playback on incoming calls and resumes afterwards.
- **Audio Visualizer**: Uses an `EventChannel` bound to Android's native `android.media.audiofx.Visualizer` (session 0). It captures true FFT audio output and streams it back to Dart for a fluid, real-time visualization on the `NowPlayingScreen`.

### Windows (SMTC & Native Shell)
- **System Media Transport Controls (SMTC)**: Uses `windows_smtc` to integrate with the Windows 10/11 taskbar volume flyout and handle hardware media keys (Play, Pause, Next, Previous).
- **Custom Window**: Uses `bitsdojo_window` to draw a custom frameless title bar matching the app's Material 3 theme.
- **Visualizer Fallback**: Due to platform constraints (lack of an easy WASAPI loopback without heavy C++ FFI), the visualizer elegantly degrades on Windows, hiding the frequency bars rather than displaying fake data.

## Performance Engineering (Phase 13 Highlights)
- **List Rendering**: O(N) inline sorting and index generation were eliminated. Alphabetical scrollbars and lists now consume pre-computed, cached data from Riverpod.
- **Image Decoding**: Fixed excessive memory pressure by ensuring `ArtworkWidget` respects `cacheWidth` and `cacheHeight` constraints based on pixel density, preventing OOM crashes when displaying grids of high-resolution album arts.
- **UI Rebuilds**: Eliminated full-screen `setState`/`ref.watch` rebuilds for the progress slider. The progress state is localized to small `Consumer` widgets.

## Testing Strategy
- **Pure Dart Logic**: Repositories and state controllers are heavily tested without UI or native dependencies.
- **Integration**: Database operations, library scanning behaviors, queue manipulations, and complex UI flows are fully verified. All `flutter test` checks (48+ unit and integration tests) pass reliably on CI.
