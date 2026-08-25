import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_library_service.dart';

void main() {
  late SonoraDatabase database;
  late DriftLibraryService libraryService;

  setUp(() {
    sqlite3.openInMemory();
    database = SonoraDatabase(
      LazyDatabase(() async => NativeDatabase.memory(logStatements: false)),
    );
    libraryService = DriftLibraryService(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> populateMockData() async {
    await database.into(database.artists).insert(
          ArtistsCompanion.insert(id: 'artist1', name: 'The Beatles'),
        );
    await database.into(database.albums).insert(
          AlbumsCompanion.insert(
            id: 'album1',
            title: 'Abbey Road',
            artistId: const Value('artist1'),
          ),
        );
    await database.into(database.songs).insert(
          SongsCompanion.insert(
            id: 'song1',
            fileUri: 'file:///here',
            title: 'Come Together',
            artistId: const Value('artist1'),
            albumId: const Value('album1'),
            artistName: const Value('The Beatles'),
            albumName: const Value('Abbey Road'),
            durationMillis: const Value(259000),
            dateAdded: Value(DateTime.now()),
            isFavorite: const Value(false),
          ),
        );

    // Another artist and song
    await database.into(database.artists).insert(
          ArtistsCompanion.insert(id: 'artist2', name: 'Pink Floyd'),
        );
    await database.into(database.albums).insert(
          AlbumsCompanion.insert(
            id: 'album2',
            title: 'The Dark Side of the Moon',
            artistId: const Value('artist2'),
          ),
        );
    await database.into(database.songs).insert(
          SongsCompanion.insert(
            id: 'song2',
            fileUri: 'file:///there',
            title: 'Time',
            artistId: const Value('artist2'),
            albumId: const Value('album2'),
            artistName: const Value('Pink Floyd'),
            albumName: const Value('The Dark Side of the Moon'),
            durationMillis: const Value(413000),
            dateAdded: Value(DateTime.now()),
            isFavorite: const Value(false),
          ),
        );
  }

  group('Library Search Tests', () {
    test('1, 2, 3, 6. Song, Artist, Album search returns categorized results', () async {
      await populateMockData();

      final result = await libraryService.search('Together');
      expect(result.songs.length, 1);
      expect(result.songs.first.title, 'Come Together');
      expect(result.albums.length, 0);
      expect(result.artists.length, 0);

      final result2 = await libraryService.search('Floyd');
      expect(result2.artists.length, 1);
      expect(result2.artists.first.name, 'Pink Floyd');
      
      final result3 = await libraryService.search('Dark Side');
      expect(result3.albums.length, 1);
      expect(result3.albums.first.name, 'The Dark Side of the Moon');
    });

    test('4. Case-insensitive search', () async {
      await populateMockData();

      final result = await libraryService.search('beaTLeS');
      expect(result.artists.length, 1);
      expect(result.artists.first.name, 'The Beatles');
      expect(result.songs.length, 1); // artistName is 'The Beatles'
    });

    test('5. Partial search', () async {
      await populateMockData();

      final result = await libraryService.search('bbey');
      expect(result.albums.length, 1);
      expect(result.albums.first.name, 'Abbey Road');
    });

    test('7. Empty query', () async {
      await populateMockData();

      final result = await libraryService.search('');
      expect(result.songs.length, 2);
      expect(result.albums.length, 2);
      expect(result.artists.length, 2);
    });

    test('8. No results', () async {
      await populateMockData();

      final result = await libraryService.search('Nonexistent query xyz');
      expect(result.songs.length, 0);
      expect(result.albums.length, 0);
      expect(result.artists.length, 0);
    });

    test('9, 10, 11, 12. Search history creation, ordering, duplicate handling, clearing', () async {
      await libraryService.saveSearchQuery('query 1');
      await Future.delayed(const Duration(seconds: 1));
      await libraryService.saveSearchQuery('query 2');
      await Future.delayed(const Duration(seconds: 1));
      await libraryService.saveSearchQuery('query 1'); // Duplicate

      final history = await libraryService.watchSearchHistory().first;
      
      // Should handle duplicates and order by most recent
      expect(history.length, 2);
      expect(history[0], 'query 1');
      expect(history[1], 'query 2');

      // Clear history
      await libraryService.clearSearchHistory();
      final historyAfterClear = await libraryService.watchSearchHistory().first;
      expect(historyAfterClear.length, 0);
    });

    test('15. Search performance/data-layer behavior', () async {
      // Create 100 songs
      for (var i = 0; i < 100; i++) {
        await database.into(database.songs).insert(
              SongsCompanion.insert(
                id: 'perf_song_$i',
                fileUri: 'file:///perf_$i',
                title: 'Performance Song $i',
                artistName: const Value('Test Artist'),
                albumName: const Value('Test Album'),
                durationMillis: const Value(100),
                dateAdded: Value(DateTime.now()),
              ),
            );
      }

      final result = await libraryService.search('Performance Song 50');
      expect(result.songs.length, 1);
      expect(result.songs.first.title, 'Performance Song 50');
    });
  });

  group('Migration Tests', () {
    test('13, 14. Database migration from schema 2 to 3 preserves data', () async {
      // Create a native database in memory
      final sqliteDb = sqlite3.openInMemory();
      
      // Simulate schema v2
      sqliteDb.execute('CREATE TABLE songs (id TEXT PRIMARY KEY, file_uri TEXT UNIQUE, title TEXT, artist_id TEXT, album_id TEXT, artist_name TEXT, album_name TEXT, genre TEXT, year INTEGER, track_number INTEGER, disc_number INTEGER, duration_millis INTEGER, artwork_path TEXT, play_count INTEGER, last_played_at INTEGER, date_added INTEGER, file_size INTEGER, is_favorite INTEGER);');
      sqliteDb.execute('INSERT INTO songs (id, file_uri, title, duration_millis, play_count, file_size, is_favorite, date_added, artist_name, album_name) VALUES (\'test1\', \'file:///test\', \'V2 Song\', 0, 0, 0, 0, 1690000000, \'Unknown Artist\', \'Unknown Album\');');
      sqliteDb.execute('PRAGMA user_version = 2;');
      
      // Open with SonoraDatabase (which expects v3)
      final v3Db = SonoraDatabase(NativeDatabase.opened(sqliteDb));
      
      // Query the song to ensure it survived migration and the DB is accessible
      final songs = await v3Db.select(v3Db.songs).get();
      expect(songs.length, 1);
      expect(songs.first.title, 'V2 Song');
      
      // Verify the new table exists
      final history = await v3Db.select(v3Db.searchHistory).get();
      expect(history.length, 0);
      
      await v3Db.close();
    });
  });
}
