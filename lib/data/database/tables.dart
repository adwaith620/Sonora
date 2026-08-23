import 'package:drift/drift.dart';

@DataClassName('ArtistEntity')
class Artists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get artworkPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AlbumEntity')
class Albums extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artistId => text().nullable().references(Artists, #id)();
  TextColumn get albumArtist => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get artworkPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SongEntity')
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get fileUri => text().unique()();
  TextColumn get title => text()();
  TextColumn get artistId => text().nullable().references(Artists, #id)();
  TextColumn get albumId => text().nullable().references(Albums, #id)();

  // Denormalized strings for fast offline display/fallback
  TextColumn get artistName =>
      text().withDefault(const Constant('Unknown Artist'))();
  TextColumn get albumName =>
      text().withDefault(const Constant('Unknown Album'))();

  TextColumn get genre => text().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get durationMillis => integer().withDefault(const Constant(0))();
  TextColumn get artworkPath => text().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistEntity')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistSongEntity')
class PlaylistSongs extends Table {
  TextColumn get playlistId =>
      text().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get songId =>
      text().references(Songs, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

@DataClassName('LibraryLocationEntity')
class LibraryLocations extends Table {
  TextColumn get id => text()();
  TextColumn get folderUri => text().unique()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
