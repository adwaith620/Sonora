import 'package:sonora/data/database/database.dart';
import 'package:sonora/data/database/drift_library_service.dart';
import 'package:sonora/data/mock_data.dart' as mock;

Future<void> seedDatabase(SonoraDatabase db) async {
  // Convert mock artists
  for (final artist in mock.mockArtists) {
    await db.libraryDao.insertArtist(
      ArtistEntity(
        id: artist.id,
        name: artist.name,
        artworkPath: artist.artworkPath,
      ),
    );
  }

  // Convert mock albums
  for (final album in mock.mockAlbums) {
    await db.libraryDao.insertAlbum(
      AlbumEntity(
        id: album.id,
        title: album.title,
        albumArtist: album.artist,
        year: album.year,
        artworkPath: album.artworkPath,
      ),
    );
  }

  // Convert mock songs
  for (final song in mock.mockSongs) {
    await db.libraryDao.insertSong(
      SongEntity(
        id: song.id,
        filePath: song.filePath,
        title: song.title,
        artistName: song.artist,
        albumName: song.album,
        durationMillis: song.duration.inMilliseconds,
        isFavorite: song.isFavorite,
        playCount: song.playCount,
        artworkPath: song.artworkPath,
        dateAdded: song.dateAdded ?? DateTime.now(),
        lastPlayedAt: song.lastPlayedAt,
      ),
    );
  }
}
