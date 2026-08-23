# Sonora Architecture

Sonora follows a layered architecture to ensure separation of concerns, testability, and future scalability.

## Layers

### 1. Presentation Layer (UI)
- **Widgets**: Flutter widgets (Material 3).
- **Navigation**: `go_router` handling adaptive shells (bottom nav vs. rail).
- **Theme**: Managed by a simple `ThemeProvider` creating `ThemeData` from dynamic colors or seeds.

### 2. State Layer (Riverpod)
- Manages application state and dependencies.
- Exposes `libraryRepositoryProvider`, `playlistRepositoryProvider`, `databaseProvider`.
- Eventually will expose state providers for Now Playing, Audio Player, etc.

### 3. Domain Models
- Immutable data classes (`Song`, `Album`, `Artist`, `Playlist`).
- Independent of database row types, ensuring the UI doesn't break if the database schema changes.

### 4. Data Layer (Repositories)
- Clean interfaces (e.g., `LibraryService`, `PlaylistService`).
- Drift (SQLite) implementations map database entities (`SongEntity`, etc.) to domain models.
- Mock data still exists for initial UI testing but should be phased out as the true services integrate.

### 5. Local Database (Drift / SQLite)
- **Tables**: `Songs`, `Albums`, `Artists`, `Playlists`, `PlaylistSongs`, `LibraryLocations`.
- **DAOs**: Organize queries (e.g., `LibraryDao`).
- Configured using `sqlite3_flutter_libs` to run cross-platform seamlessly.

## Database Schema Highlights
- `Songs` holds file paths, metadata, duration, favorites status, play counts, and foreign keys to `Albums` and `Artists`.
- Strings are denormalized inside `Songs` (e.g. `artistName`, `albumName`) as fallbacks for fast UI rendering, but true relational views are supported.
- `PlaylistSongs` acts as a join table with a `position` column.

## Future Plans (Phase 3 & 4)
- **Phase 3: Real Audio Engine**
- **MediaKitAudioService**: Wraps `media_kit` native player. Plays real files or remote URLs.
- **SonoraAudioHandler**: Extends `audio_service` `BaseAudioHandler` to broadcast playback state to the Android OS.
- **PlaybackStateNotifier**: A pure Dart Riverpod Notifier that controls queue manipulation (shuffle, repeat, add, remove). It is easily testable without a UI or native plugins.

- **Phase 4: Local Library Scanner & Metadata**
- **File Scanner**: `LocalScannerService` recursively scans directories configured in the `LibraryLocations` table using `dart:io`.
- **Metadata Extraction**: Uses the pure-Dart `audio_metadata_reader` package to parse ID3, Vorbis, and MP4 tags without FFI or native plugin complications. Falls back to filename if tags are missing.
- **Artwork Cache**: Embedded artwork (e.g. ID3 APIC frames) is extracted and cached in the application's support directory. A SHA-256 hash of the image bytes prevents duplicate image files.
- **Incremental Sync**: The scanner compares file paths and file sizes before extracting tags to avoid unnecessary read overhead on subsequent rescans.
- **Missing Files**: Tracks discovered files during the scan and deletes database records for files that are no longer present on the filesystem.
- **Concurrency & Yielding**: Progress updates are yielded to Riverpod periodically, ensuring the main Flutter isolate remains responsive.
- **Permissions**: Android builds request `MANAGE_EXTERNAL_STORAGE` and `READ_MEDIA_AUDIO` to correctly access the local file system using the SAF folder picker (`file_picker`). Windows builds rely on native filesystem permissions without explicit requests.
