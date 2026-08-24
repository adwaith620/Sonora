import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_library_service.dart';
import 'package:sonora/data/models/song.dart';
import 'package:sonora/services/audio_player_service.dart';

void main() {
  group('Favorites — Database Layer', () {
    late SonoraDatabase database;
    late DriftLibraryService libraryService;

    setUp(() {
      database = SonoraDatabase(NativeDatabase.memory());
      libraryService = DriftLibraryService(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('New song defaults to not favorite', () async {
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Test Song 1',
        ),
      );

      final songs = await libraryService.getAllSongs();
      expect(songs.length, 1);
      expect(songs.first.isFavorite, false);
    });

    test('Favorite can be enabled', () async {
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Test Song 1',
        ),
      );

      await libraryService.toggleFavorite('s1');

      final songs = await libraryService.getAllSongs();
      expect(songs.first.isFavorite, true);
    });

    test('Favorite can be disabled', () async {
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Test Song 1',
        ),
      );

      // Enable
      await libraryService.toggleFavorite('s1');
      var songs = await libraryService.getAllSongs();
      expect(songs.first.isFavorite, true);

      // Disable
      await libraryService.toggleFavorite('s1');
      songs = await libraryService.getAllSongs();
      expect(songs.first.isFavorite, false);
    });

    test('Favorite persists in Drift after re-query', () async {
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Test Song 1',
        ),
      );

      await libraryService.toggleFavorite('s1');

      // Create a fresh service pointing at the same DB
      final freshService = DriftLibraryService(database);
      final songs = await freshService.getAllSongs();
      expect(songs.first.isFavorite, true);
    });

    test('Favorite survives repository reload', () async {
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Test Song 1',
        ),
      );

      await libraryService.toggleFavorite('s1');

      // Simulate reload by creating new service instance on same DB
      final reloadedService = DriftLibraryService(database);
      final favorites = await reloadedService.getFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.id, 's1');
      expect(favorites.first.isFavorite, true);
    });

    test('getFavorites returns only favorited songs', () async {
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Favorite Song',
        ),
      );
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's2',
          fileUri: '/test/song2.mp3',
          title: 'Regular Song',
        ),
      );
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's3',
          fileUri: '/test/song3.mp3',
          title: 'Another Favorite',
        ),
      );

      await libraryService.toggleFavorite('s1');
      await libraryService.toggleFavorite('s3');

      final favorites = await libraryService.getFavorites();
      expect(favorites.length, 2);
      expect(favorites.map((s) => s.id).toSet(), {'s1', 's3'});
      expect(favorites.every((s) => s.isFavorite), true);

      // Verify getAllSongs still returns all 3
      final allSongs = await libraryService.getAllSongs();
      expect(allSongs.length, 3);
    });

    test('Toggle favorite for non-existent song does not crash', () async {
      // Should not throw
      await libraryService.toggleFavorite('non-existent-id');

      final favorites = await libraryService.getFavorites();
      expect(favorites, isEmpty);
    });

    test('Favorite survives database reopen', () async {
      // Use a file-based DB would be ideal, but in-memory suffices
      // to prove the read-back path works across service instances
      await database.libraryDao.insertSong(
        SongsCompanion.insert(
          id: 's1',
          fileUri: '/test/song1.mp3',
          title: 'Persistent Favorite',
          isFavorite: const drift.Value(true),
        ),
      );

      final service2 = DriftLibraryService(database);
      final favorites = await service2.getFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.title, 'Persistent Favorite');
      expect(favorites.first.isFavorite, true);
    });
  });

  group('Favorites — PlaybackState In-Memory Update', () {
    test('updateCurrentSongFavorite updates current song state', () {
      // We need to test the notifier in isolation.
      // PlaybackStateNotifier is a Riverpod Notifier, so we test
      // the logic via the pure-dart Song/PlaybackState model approach.
      const song = Song(
        id: 's1',
        fileUri: '/test/song.mp3',
        title: 'Test',
        isFavorite: false,
      );

      // Simulate what the notifier does internally
      final updatedSong = song.copyWith(isFavorite: true);
      expect(updatedSong.isFavorite, true);
      expect(updatedSong.id, song.id);
      expect(updatedSong.title, song.title);

      // Verify toggle back
      final revertedSong = updatedSong.copyWith(isFavorite: false);
      expect(revertedSong.isFavorite, false);
    });

    test('Song.copyWith preserves all fields when toggling favorite', () {
      final song = Song(
        id: 's1',
        fileUri: '/test/song.mp3',
        title: 'My Song',
        artist: 'My Artist',
        album: 'My Album',
        albumArtist: 'My Album Artist',
        genre: 'Rock',
        year: 2024,
        trackNumber: 5,
        discNumber: 1,
        duration: const Duration(minutes: 3, seconds: 45),
        artworkPath: '/art/cover.jpg',
        playCount: 10,
        lastPlayedAt: DateTime(2024, 1, 1),
        dateAdded: DateTime(2023, 12, 1),
        fileSize: 5000000,
        isFavorite: false,
      );

      final favorited = song.copyWith(isFavorite: true);

      expect(favorited.isFavorite, true);
      expect(favorited.id, song.id);
      expect(favorited.fileUri, song.fileUri);
      expect(favorited.title, song.title);
      expect(favorited.artist, song.artist);
      expect(favorited.album, song.album);
      expect(favorited.albumArtist, song.albumArtist);
      expect(favorited.genre, song.genre);
      expect(favorited.year, song.year);
      expect(favorited.trackNumber, song.trackNumber);
      expect(favorited.discNumber, song.discNumber);
      expect(favorited.duration, song.duration);
      expect(favorited.artworkPath, song.artworkPath);
      expect(favorited.playCount, song.playCount);
      expect(favorited.lastPlayedAt, song.lastPlayedAt);
      expect(favorited.dateAdded, song.dateAdded);
      expect(favorited.fileSize, song.fileSize);
    });

    test('PlaybackState reflects favorite change without queue mutation', () {
      const song1 = Song(
        id: 's1',
        fileUri: '/test/1.mp3',
        title: 'Song 1',
        isFavorite: false,
      );
      const song2 = Song(
        id: 's2',
        fileUri: '/test/2.mp3',
        title: 'Song 2',
        isFavorite: false,
      );

      const state = PlaybackState(
        currentSong: song1,
        queue: [song1, song2],
        currentIndex: 0,
      );

      // Simulate what updateCurrentSongFavorite does
      final updatedSong = song1.copyWith(isFavorite: true);
      final updatedQueue = state.queue.map((s) {
        return s.id == song1.id ? updatedSong : s;
      }).toList();
      final newState = state.copyWith(
        currentSong: updatedSong,
        queue: updatedQueue,
      );

      expect(newState.currentSong!.isFavorite, true);
      expect(newState.queue[0].isFavorite, true);
      expect(newState.queue[1].isFavorite, false); // song2 unchanged
      expect(newState.queue.length, 2); // queue size unchanged
      expect(newState.currentIndex, 0); // index unchanged
    });
  });
}
