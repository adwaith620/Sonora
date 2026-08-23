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
- **File Scanner**: A local isolate-based scanner to traverse `LibraryLocations` and extract ID3/FLAC metadata via `metadata_god`.
- **Audio Engine**: `media_kit` implementations for `AudioPlayerService`.
