// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$LibraryDaoMixin on DatabaseAccessor<SonoraDatabase> {
  $ArtistsTable get artists => attachedDatabase.artists;
  $AlbumsTable get albums => attachedDatabase.albums;
  $SongsTable get songs => attachedDatabase.songs;
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $PlaylistSongsTable get playlistSongs => attachedDatabase.playlistSongs;
  $LibraryLocationsTable get libraryLocations =>
      attachedDatabase.libraryLocations;
  LibraryDaoManager get managers => LibraryDaoManager(this);
}

class LibraryDaoManager {
  final _$LibraryDaoMixin _db;
  LibraryDaoManager(this._db);
  $$ArtistsTableTableManager get artists =>
      $$ArtistsTableTableManager(_db.attachedDatabase, _db.artists);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db.attachedDatabase, _db.albums);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db.attachedDatabase, _db.songs);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$PlaylistSongsTableTableManager get playlistSongs =>
      $$PlaylistSongsTableTableManager(_db.attachedDatabase, _db.playlistSongs);
  $$LibraryLocationsTableTableManager get libraryLocations =>
      $$LibraryLocationsTableTableManager(
        _db.attachedDatabase,
        _db.libraryLocations,
      );
}
