import 'package:drift/drift.dart';

import 'database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(
  tables: [Songs, Albums, Artists, Playlists, PlaylistSongs, LibraryLocations, SearchHistory],
)
class LibraryDao extends DatabaseAccessor<SonoraDatabase>
    with _$LibraryDaoMixin {
  LibraryDao(super.db);

  // === Library Locations ===
  Future<List<LibraryLocationEntity>> getLibraryLocations() =>
      select(libraryLocations).get();

  Future<void> addLibraryLocation(String folderUri) =>
      into(libraryLocations).insert(
        LibraryLocationsCompanion.insert(
          id: folderUri,
          folderUri: folderUri,
          isEnabled: const Value(true),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> removeLibraryLocation(String folderUri) =>
      (delete(libraryLocations)..where((t) => t.id.equals(folderUri))).go();

  // === Songs ===
  Future<List<SongEntity>> getAllSongs() => select(songs).get();

  Stream<List<SongEntity>> watchAllSongs() => select(songs).watch();

  Future<List<String>> getAllSongPaths() async {
    final query = selectOnly(songs)..addColumns([songs.fileUri]);
    return query.map((row) => row.read(songs.fileUri)!).get();
  }

  Future<void> removeSongsByPaths(List<String> uris) async {
    if (uris.isEmpty) return;
    await (delete(songs)..where((t) => t.fileUri.isIn(uris))).go();
  }

  Future<SongEntity?> getSongById(String id) =>
      (select(songs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<SongEntity?> getSongByPath(String uri) =>
      (select(songs)..where((t) => t.fileUri.equals(uri))).getSingleOrNull();

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

  Stream<List<AlbumEntity>> watchAllAlbums() => select(albums).watch();

  Future<AlbumEntity?> getAlbumById(String id) =>
      (select(albums)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<AlbumEntity?> getAlbumByTitleAndArtist(
    String title,
    String artistId,
  ) =>
      (select(albums)
            ..where((t) => t.title.equals(title) & t.artistId.equals(artistId)))
          .getSingleOrNull();

  Future<void> insertAlbum(Insertable<AlbumEntity> album) =>
      into(albums).insert(album, mode: InsertMode.insertOrReplace);

  Future<void> insertAlbums(List<Insertable<AlbumEntity>> items) async {
    await batch(
      (b) => b.insertAll(albums, items, mode: InsertMode.insertOrReplace),
    );
  }

  Future<List<SongEntity>> getSongsForAlbum(String albumId) =>
      (select(songs)..where((t) => t.albumId.equals(albumId))).get();

  Future<List<AlbumEntity>> getAlbumsForArtist(String artistId) =>
      (select(albums)..where((t) => t.artistId.equals(artistId))).get();

  // === Artists ===
  Future<List<ArtistEntity>> getAllArtists() => select(artists).get();

  Stream<List<ArtistEntity>> watchAllArtists() => select(artists).watch();

  Future<ArtistEntity?> getArtistById(String id) =>
      (select(artists)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ArtistEntity?> getArtistByName(String name) =>
      (select(artists)..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<void> insertArtist(Insertable<ArtistEntity> artist) =>
      into(artists).insert(artist, mode: InsertMode.insertOrReplace);

  Future<void> insertArtists(List<Insertable<ArtistEntity>> items) async {
    await batch(
      (b) => b.insertAll(artists, items, mode: InsertMode.insertOrReplace),
    );
  }

  Future<List<SongEntity>> getSongsForArtist(String artistId) =>
      (select(songs)..where((t) => t.artistId.equals(artistId))).get();

  // === Playlists ===
  Future<List<PlaylistEntity>> getAllPlaylists() => select(playlists).get();

  Stream<List<PlaylistEntity>> watchAllPlaylists() => select(playlists).watch();

  Stream<PlaylistEntity?> watchPlaylist(String id) =>
      (select(playlists)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> insertPlaylist(Insertable<PlaylistEntity> playlist) =>
      into(playlists).insert(playlist, mode: InsertMode.insertOrReplace);

  Future<void> addSongToPlaylist(
    String playlistId,
    String songId,
    int position,
  ) => into(playlistSongs).insert(
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

  Stream<List<SongEntity>> watchSongsForPlaylist(String playlistId) {
    final query =
        select(songs).join([
            innerJoin(playlistSongs, playlistSongs.songId.equalsExp(songs.id)),
          ])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistSongs.position)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(songs)).toList(),
    );
  }

  // === Generic queries ===
  Future<List<SongEntity>> getRecentlyPlayed({int limit = 20}) =>
      (select(songs)
            ..where((t) => t.lastPlayedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(limit))
          .get();

  Stream<List<SongEntity>> watchRecentlyPlayed({int limit = 20}) =>
      (select(songs)
            ..where((t) => t.lastPlayedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(limit))
          .watch();

  Future<List<SongEntity>> getRecentlyAdded({int limit = 20}) =>
      (select(songs)
            ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])
            ..limit(limit))
          .get();

  Stream<List<SongEntity>> watchRecentlyAdded({int limit = 20}) =>
      (select(songs)
            ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])
            ..limit(limit))
          .watch();

  Future<List<SongEntity>> getFavorites() =>
      (select(songs)..where((t) => t.isFavorite.equals(true))).get();

  Stream<List<SongEntity>> watchFavorites() =>
      (select(songs)..where((t) => t.isFavorite.equals(true))).watch();

  // === Search ===
  Future<List<SongEntity>> searchSongs(String query) {
    return (select(songs)
          ..where(
            (t) =>
                t.title.like('%$query%') |
                t.artistName.like('%$query%') |
                t.albumName.like('%$query%'),
          )
          ..limit(50))
        .get();
  }

  Future<List<AlbumEntity>> searchAlbums(String query) {
    return (select(albums)
          ..where((t) => t.title.like('%$query%') | t.albumArtist.like('%$query%'))
          ..limit(20))
        .get();
  }

  Future<List<ArtistEntity>> searchArtists(String query) {
    return (select(artists)
          ..where((t) => t.name.like('%$query%'))
          ..limit(20))
        .get();
  }

  // === Search History ===
  Stream<List<SearchHistoryEntity>> watchSearchHistory() {
    return (select(searchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(20))
        .watch();
  }

  Future<void> addSearchHistory(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    await into(searchHistory).insert(
      SearchHistoryCompanion.insert(
        query: cleanQuery,
        timestamp: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeSearchHistory(String query) async {
    await (delete(searchHistory)..where((t) => t.query.equals(query))).go();
  }

  Future<void> clearSearchHistory() async {
    await delete(searchHistory).go();
  }
}
