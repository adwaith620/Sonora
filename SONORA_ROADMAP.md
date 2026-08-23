# Sonora Roadmap

This document tracks the progress of the Sonora project milestones.

## Phase 1: Foundation + UI (✅ Complete)
- [x] Flutter project structure
- [x] Material 3 design system setup
- [x] Theme system (Light, Dark, System, OLED)
- [x] Adaptive navigation shell (BottomNav for mobile, NavRail for desktop)
- [x] Core service interfaces (Audio, Library, Playlists)
- [x] Mock data layer for UI development
- [x] Main UI Screens (Home, Songs, Albums, Artists, Playlists, Settings)
- [x] Player UI (Mini Player, Now Playing modal)

## Phase 2: Local Database + Models (✅ Complete)
- [x] Setup Drift SQLite database
- [x] Define normalized database tables (Songs, Albums, Artists, Playlists)
- [x] Implement DAO layer
- [x] Create data migration strategy
- [x] Connect repository pattern to UI state

## Milestone 3: Real Audio Engine (Phase 3)
*Status: [x] Completed*

**Goal:** Replace the mock playback behavior with a real local audio playback system.

- [x] **Audio framework integration**
  - Integrate `media_kit` for cross-platform audio playback.
  - Integrate `audio_service` for Android background playback integration.
- [x] **Playback service layer**
  - Implement `AudioPlayerService` wrapping `media_kit`.
  - Create robust Riverpod `PlaybackState` (current song, playing, buffered, queue).
- [x] **Queue management**
  - Implement queue list, play next, play previous, shuffle, and repeat.
  - Isolate queue logic for pure Dart testing.
- [x] **UI integration**
  - Connect `MiniPlayer` to real `AudioPlayerService`.
  - Connect `NowPlayingScreen` to real `AudioPlayerService`.
- [x] **Testing**
  - Create pure Dart tests for queue manipulation logic.
  - Verify Android APK build.

### Phase 4: Local Library Scanner 🟢 (COMPLETED)
- [x] Configure Android scoped storage / file picker permissions (Migrated to native SAF)
- [x] Implement music folder selection UI
- [x] Create recursive file scanner for supported audio formats
- [x] Extract metadata (pure Dart `audio_metadata_reader`)
- [x] Handle artwork extraction and cache deduplication
- [x] Implement incremental upsert into Drift Database
- [x] Provide Riverpod streams for scan progress/state
- [x] Connect database output to Library UI screens

## Phase 5: Player UI Integration
- [ ] Connect Mini Player to live playback state
- [ ] Connect Now Playing to live playback state
- [ ] Interactive seek bar
- [ ] Real-time queue UI
- [ ] Artwork crossfading

## Phase 6: Home Screen + Library UI
- [ ] Connect Home screen carousels to real library queries
- [ ] Implement recently added/played tracking
- [ ] Implement sorting/filtering in Songs/Albums/Artists screens
- [ ] Alphabetical fast-scroll indexes

## Phase 7: Playlists + Favorites
- [ ] User-created playlists
- [ ] Add/remove songs to playlists
- [ ] Favorites toggle logic
- [ ] Smart playlists (Most played, recently added)

## Phase 8: Search
- [ ] Fast local full-text search
- [ ] Categorized results (Songs, Artists, Albums)
- [ ] Search history

## Phase 9: Audio Visualizer
- [ ] Extract FFT/audio data stream
- [ ] Custom painter for waveform/frequency visualization
- [ ] Sync visualization with playback

## Phase 10: Android Platform Integration
- [ ] MediaSession controls
- [ ] Lock screen/notification player
- [ ] Android Auto compatibility stub
- [ ] Audio focus handling (pause on call)

## Phase 11: Windows Platform Integration
- [ ] System Media Transport Controls (SMTC)
- [ ] Hardware media keys support
- [ ] Taskbar thumbnail controls
- [ ] Custom titlebar styling

## Phase 12-15: Polish & Release
- [ ] Comprehensive testing (Unit, Widget, Integration)
- [ ] Performance profiling & optimization
- [ ] Animations, hero transitions, haptics
- [ ] Final documentation and builds
