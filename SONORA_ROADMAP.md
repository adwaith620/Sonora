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

## Phase 2: Local Database + Models (🔜 Next)
- [ ] Setup Drift SQLite database
- [ ] Define normalized database tables (Songs, Albums, Artists, Playlists)
- [ ] Implement DAO layer
- [ ] Create data migration strategy
- [ ] Connect repository pattern to UI state

## Phase 3: Library Scanner + Metadata
- [ ] Platform-specific local storage permissions
- [ ] Fast filesystem traversal
- [ ] Metadata extraction (ID3, FLAC, etc.) using `metadata_god`
- [ ] Artwork extraction and caching strategy
- [ ] Sync engine to populate local database

## Phase 4: Audio Playback Engine
- [ ] Integrate `media_kit` for cross-platform audio
- [ ] Implement `AudioPlayerService`
- [ ] Playback queue management
- [ ] Shuffle and repeat logic
- [ ] Gapless playback preparation

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
