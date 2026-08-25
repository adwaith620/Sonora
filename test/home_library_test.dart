import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_library_service.dart';
import 'package:sonora/data/models/album.dart';
import 'package:sonora/data/models/artist.dart';
import 'package:sonora/data/models/song.dart';
import 'package:sonora/services/library_service.dart';

void main() {
  late SonoraDatabase db;
  late DriftLibraryService libraryService;

  setUp(() {
    db = SonoraDatabase(NativeDatabase.memory());
    libraryService = DriftLibraryService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'LibraryService returns recently added songs in correct order',
    () async {
      await db.into(db.songs).insert(
            SongsCompanion.insert(
              id: '1',
              fileUri: 'file1',
              title: 'First Song',
              artistName: const Value('Artist 1'),
              durationMillis: const Value(1000),
              dateAdded: Value(DateTime.now().subtract(const Duration(days: 2))),
            ),
          );

      await db.into(db.songs).insert(
            SongsCompanion.insert(
              id: '2',
              fileUri: 'file2',
              title: 'Second Song',
              artistName: const Value('Artist 2'),
              durationMillis: const Value(2000),
              dateAdded: Value(DateTime.now()),
            ),
          );

      final recentlyAdded = await libraryService.getRecentlyAdded(limit: 10);

      expect(recentlyAdded.length, 2);
      expect(recentlyAdded.first.title, 'Second Song');
      expect(recentlyAdded.last.title, 'First Song');
    },
  );

  test('LibraryService updates recently played when recordPlay is called', () async {
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: '1',
            fileUri: 'file1_rp',
            title: 'Song 1',
            artistName: const Value('Artist 1'),
            durationMillis: const Value(1000),
            dateAdded: Value(DateTime.now()),
          ),
        );

    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: '2',
            fileUri: 'file2_rp',
            title: 'Song 2',
            artistName: const Value('Artist 2'),
            durationMillis: const Value(2000),
            dateAdded: Value(DateTime.now()),
          ),
        );

    // Initial state: no recently played
    final initialPlayed = await libraryService.getRecentlyPlayed(limit: 10);
    expect(initialPlayed.isEmpty, true);

    // Record play for Song 2
    await libraryService.recordPlay('2');
    
    var played = await libraryService.getRecentlyPlayed(limit: 10);
    expect(played.length, 1);
    expect(played.first.title, 'Song 2');

    // Wait a millisecond to ensure time difference
    await Future.delayed(const Duration(milliseconds: 10));

    // Record play for Song 1
    await libraryService.recordPlay('1');
    
    played = await libraryService.getRecentlyPlayed(limit: 10);
    expect(played.length, 2);
    expect(played.first.title, 'Song 1'); // Most recently played first
    expect(played.last.title, 'Song 2');
  });

  test('LibraryService sorting works for songs', () async {
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: '2',
            fileUri: 'file2_sort',
            title: 'B Song',
            artistName: const Value('Z Artist'),
            durationMillis: const Value(1000),
            dateAdded: Value(DateTime.now()),
          ),
        );
    await db.into(db.songs).insert(
          SongsCompanion.insert(
            id: '1',
            fileUri: 'file1_sort',
            title: 'A Song',
            artistName: const Value('Y Artist'),
            durationMillis: const Value(1000),
            dateAdded: Value(DateTime.now()),
          ),
        );

    final byTitle = await libraryService.getAllSongs(
      sortBy: SongSortField.title,
    );
    expect(byTitle.first.title, 'A Song');

    final byArtist = await libraryService.getAllSongs(
      sortBy: SongSortField.artist,
    );
    expect(byArtist.first.title, 'A Song'); // Y Artist is before Z Artist
  });
}
