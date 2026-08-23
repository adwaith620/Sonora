import 'package:drift/drift.dart';

import 'database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Songs, Albums, Artists, Playlists, PlaylistSongs])
class LibraryDao extends DatabaseAccessor<SonoraDatabase>
    with _$LibraryDaoMixin {
  LibraryDao(super.db);

  // === Songs ===
  Future<List<SongEntity>> getAllSongs() => select(songs).get();

  Stream<List<SongEntity>> watchAllSongs() => select(songs).watch();

  Future<SongEntity?> getSongById(String id) =>
      (select(songs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertSong(Insertable<SongEntity> song) =>
      into(songs).insert(song, mode: InsertMode.insertOrReplace);

  Future<void> insertSongs(List<Insertable<SongEntity>> items) async {
    await batch(
      (b) => b.insertAll(songs, items, mode: InsertMode.insertOrReplace),
    );
  }

  Future<void> toggleFavorite(String songId) async {
    final song = await getSongById(songId);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(songId))).write(
        SongsCompanion(isFavorite: Value(!song.isFavorite)),
      );
    }
  }

  Future<void> recordPlay(String songId) async {
    final song = await getSongById(songId);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(songId))).write(
        SongsCompanion(
          playCount: Value(song.playCount + 1),
          lastPlayedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // === Albums ===
  Future<List<AlbumEntity>> getAllAlbums() => select(albums).get();

  Future<AlbumEntity?> getAlbumById(String id) =>
      (select(albums)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertAlbum(Insertable<AlbumEntity> album) =>
      into(albums).insert(album, mode: InsertMode.insertOrReplace);

  Future<void> insertAlbums(List<Insertable<AlbumEntity>> items) async {
    await batch((b) => b.insertAll(albums, items, mode: InsertMode.insertOrReplace));
  }
  
  Future<List<SongEntity>> getSongsForAlbum(String albumId) =>
      (select(songs)..where((t) => t.albumId.equals(albumId))).get();

  // === Artists ===
  Future<List<ArtistEntity>> getAllArtists() => select(artists).get();
  
  Future<ArtistEntity?> getArtistById(String id) =>
      (select(artists)..where((t) => t.id.equals(id))).getSingleOrNull();
      
  Future<void> insertArtist(Insertable<ArtistEntity> artist) =>
      into(artists).insert(artist, mode: InsertMode.insertOrReplace);
      
  Future<void> insertArtists(List<Insertable<ArtistEntity>> items) async {
    await batch((b) => b.insertAll(artists, items, mode: InsertMode.insertOrReplace));
  }

  Future<List<SongEntity>> getSongsForArtist(String artistId) =>
      (select(songs)..where((t) => t.artistId.equals(artistId))).get();

  // === Playlists ===
  Future<List<PlaylistEntity>> getAllPlaylists() => select(playlists).get();

  Future<void> insertPlaylist(Insertable<PlaylistEntity> playlist) =>
      into(playlists).insert(playlist, mode: InsertMode.insertOrReplace);

  Future<void> addSongToPlaylist(
      String playlistId, String songId, int position) =>
      into(playlistSongs).insert(
        PlaylistSongsCompanion.insert(
          playlistId: playlistId,
          songId: songId,
          position: position,
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<List<SongEntity>> getSongsForPlaylist(String playlistId) {
    final query =
        select(songs).join([
            innerJoin(playlistSongs, playlistSongs.songId.equalsExp(songs.id)),
          ])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistSongs.position)]);

    return query.map((row) => row.readTable(songs)).get();
  }

  // === Generic queries ===
  Future<List<SongEntity>> getRecentlyPlayed({int limit = 20}) =>
      (select(songs)
            ..where((t) => t.lastPlayedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(limit))
          .get();

  Future<List<SongEntity>> getRecentlyAdded({int limit = 20}) =>
      (select(songs)
            ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])
            ..limit(limit))
          .get();

  Future<List<SongEntity>> getFavorites() =>
      (select(songs)..where((t) => t.isFavorite.equals(true))).get();
}
