import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_library_service.dart';
import 'package:sonora/data/database/drift_playlist_service.dart';

void main() {
  late SonoraDatabase database;
  late DriftLibraryService libraryService;
  late DriftPlaylistService playlistService;

  setUp(() {
    database = SonoraDatabase(NativeDatabase.memory());
    libraryService = DriftLibraryService(database);
    playlistService = DriftPlaylistService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Songs can be inserted and retrieved', () async {
    const songId = 's1';
    await database.libraryDao.insertSong(
      SongsCompanion.insert(
        id: songId,
        filePath: '/music/test.mp3',
        title: 'Test Song',
        durationMillis: const drift.Value(120000),
      ),
    );

    final songs = await libraryService.getAllSongs();
    expect(songs.length, 1);
    expect(songs.first.id, songId);
    expect(songs.first.title, 'Test Song');
    expect(songs.first.artist, 'Unknown Artist');
  });

  test('Albums can be inserted and songs retrieved for album', () async {
    await database.libraryDao.insertAlbum(
      AlbumsCompanion.insert(
        id: 'a1',
        title: 'Test Album',
        albumArtist: const drift.Value('Test Artist'),
      ),
    );

    await database.libraryDao.insertSong(
      SongsCompanion.insert(
        id: 's1',
        filePath: '/music/test1.mp3',
        title: 'Test Song 1',
        albumId: const drift.Value('a1'),
        albumName: const drift.Value('Test Album'),
      ),
    );

    final albums = await libraryService.getAllAlbums();
    expect(albums.length, 1);
    expect(albums.first.name, 'Test Album');

    final albumSongs = await libraryService.getSongsForAlbum('a1');
    expect(albumSongs.length, 1);
    expect(albumSongs.first.title, 'Test Song 1');
  });

  test('Playlists can be created and songs added/reordered', () async {
    await database.libraryDao.insertSong(
      SongsCompanion.insert(id: 's1', filePath: '1.mp3', title: 'S1'),
    );
    await database.libraryDao.insertSong(
      SongsCompanion.insert(id: 's2', filePath: '2.mp3', title: 'S2'),
    );
    await database.libraryDao.insertSong(
      SongsCompanion.insert(id: 's3', filePath: '3.mp3', title: 'S3'),
    );

    final playlist = await playlistService.createPlaylist('My Playlist');
    expect(playlist.name, 'My Playlist');

    await playlistService.addSong(playlist.id, 's1');
    await playlistService.addSong(playlist.id, 's2');
    await playlistService.addSong(playlist.id, 's3');

    var songs = await playlistService.getPlaylistSongs(playlist.id);
    expect(songs.length, 3);
    expect(songs[0].id, 's1');
    expect(songs[1].id, 's2');
    expect(songs[2].id, 's3');

    // Reorder s3 to the top
    await playlistService.reorderSongs(playlist.id, 2, 0);

    songs = await playlistService.getPlaylistSongs(playlist.id);
    expect(songs[0].id, 's3');
    expect(songs[1].id, 's1');
    expect(songs[2].id, 's2');
  });

  test('Favorites and recently played work correctly', () async {
    await database.libraryDao.insertSong(
      SongsCompanion.insert(id: 's1', filePath: '1.mp3', title: 'S1'),
    );

    await libraryService.toggleFavorite('s1');

    final favs = await libraryService.getFavorites();
    expect(favs.length, 1);
    expect(favs.first.isFavorite, true);

    await libraryService.recordPlay('s1');

    final recents = await libraryService.getRecentlyPlayed();
    expect(recents.length, 1);
    expect(recents.first.playCount, 1);
    expect(recents.first.lastPlayedAt, isNotNull);
  });
}
