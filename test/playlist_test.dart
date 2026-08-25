import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_playlist_service.dart';

void main() {
  late SonoraDatabase db;
  late DriftPlaylistService playlistService;

  setUp(() {
    db = SonoraDatabase(NativeDatabase.memory());
    playlistService = DriftPlaylistService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Create, Rename, Delete Playlist', () async {
    // Create
    final playlist = await playlistService.createPlaylist('My Playlist');
    expect(playlist.name, 'My Playlist');

    // Fetch
    final fetched = await playlistService.getPlaylist(playlist.id);
    expect(fetched?.name, 'My Playlist');

    // Rename
    await playlistService.renamePlaylist(playlist.id, 'Renamed Playlist');
    final renamed = await playlistService.getPlaylist(playlist.id);
    expect(renamed?.name, 'Renamed Playlist');

    // Delete
    await playlistService.deletePlaylist(playlist.id);
    final deleted = await playlistService.getPlaylist(playlist.id);
    expect(deleted, isNull);
  });

  test('Add, Reorder, Remove Songs', () async {
    // Insert mock songs
    await db
        .into(db.artists)
        .insert(ArtistsCompanion.insert(id: 'ar1', name: 'Artist 1'));
    await db
        .into(db.songs)
        .insert(
          SongsCompanion.insert(id: 's1', title: 'Song 1', fileUri: 'uri1'),
        );
    await db
        .into(db.songs)
        .insert(
          SongsCompanion.insert(id: 's2', title: 'Song 2', fileUri: 'uri2'),
        );
    await db
        .into(db.songs)
        .insert(
          SongsCompanion.insert(id: 's3', title: 'Song 3', fileUri: 'uri3'),
        );

    final playlist = await playlistService.createPlaylist('Test Playlist');

    // Add songs
    await playlistService.addSong(playlist.id, 's1');
    await playlistService.addSong(playlist.id, 's2');
    await playlistService.addSong(playlist.id, 's3');

    var songs = await playlistService.getPlaylistSongs(playlist.id);
    expect(songs.length, 3);
    expect(songs[0].id, 's1');
    expect(songs[1].id, 's2');
    expect(songs[2].id, 's3');

    // Reorder: Move 's1' (index 0) to index 2 (after 's2')
    // newIndex in Flutter ReorderableList behaves such that if we move down, we use newIndex
    // Wait, the test uses the service method. DriftPlaylistService:
    // target = removeAt(oldIndex);
    // if (newIndex > oldIndex) newIndex -= 1;
    // insert(newIndex, target);
    await playlistService.reorderSongs(playlist.id, 0, 2);

    songs = await playlistService.getPlaylistSongs(playlist.id);
    expect(songs[0].id, 's2');
    expect(songs[1].id, 's1');
    expect(songs[2].id, 's3');

    // Remove song
    await playlistService.removeSong(playlist.id, 's1');
    songs = await playlistService.getPlaylistSongs(playlist.id);
    expect(songs.length, 2);
    expect(songs[0].id, 's2');
    expect(songs[1].id, 's3');
  });
}
