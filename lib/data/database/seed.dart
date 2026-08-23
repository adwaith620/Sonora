import 'package:drift/drift.dart' as drift;
import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_library_service.dart';
import 'package:sonora/data/mock_data.dart' as mock;

Future<void> seedDatabase(SonoraDatabase db) async {
  // Convert mock artists
  for (final artist in mock.mockArtists) {
    await db.libraryDao.insertArtist(ArtistsCompanion.insert(
      id: artist.id,
      name: artist.name,
      artworkPath: drift.Value(artist.artworkPath),
    ));
  }

  // Convert mock albums
  for (final album in mock.mockAlbums) {
    await db.libraryDao.insertAlbum(AlbumsCompanion.insert(
      id: album.id,
      title: album.name,
      albumArtist: drift.Value(album.artist),
      year: drift.Value(album.year),
      artworkPath: drift.Value(album.artworkPath),
    ));
  }

  // Convert mock songs
  for (final song in mock.mockSongs) {
    await db.libraryDao.insertSong(SongsCompanion.insert(
      id: song.id,
      filePath: song.filePath,
      title: song.title,
      artistName: drift.Value(song.artist),
      albumName: drift.Value(song.album),
      durationMillis: drift.Value(song.duration.inMilliseconds),
      isFavorite: drift.Value(song.isFavorite),
      playCount: drift.Value(song.playCount),
      artworkPath: drift.Value(song.artworkPath),
      dateAdded: drift.Value(song.dateAdded ?? DateTime.now()),
      lastPlayedAt: drift.Value(song.lastPlayedAt),
    ));
  }
}
