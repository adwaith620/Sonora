import '../../services/library_service.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';
import 'database.dart';

/// Extension to map Drift entities to domain models
extension SongEntityMapper on SongEntity {
  Song toDomain() {
    return Song(
      id: id,
      fileUri: fileUri,
      title: title,
      artist: artistName,
      album: albumName,
      genre: genre,
      year: year,
      trackNumber: trackNumber,
      discNumber: discNumber,
      duration: Duration(milliseconds: durationMillis),
      artworkPath: artworkPath,
      playCount: playCount,
      lastPlayedAt: lastPlayedAt,
      dateAdded: dateAdded,
      fileSize: fileSize,
      isFavorite: isFavorite,
    );
  }
}

extension AlbumEntityMapper on AlbumEntity {
  Album toDomain() {
    return Album(
      id: id,
      name: title,
      artist: albumArtist ?? 'Unknown Artist',
      year: year,
      artworkPath: artworkPath,
    );
  }
}

extension ArtistEntityMapper on ArtistEntity {
  Artist toDomain() {
    return Artist(id: id, name: name, artworkPath: artworkPath);
  }
}

/// Implementation of LibraryService backed by Drift SQLite.
class DriftLibraryService implements LibraryService {
  DriftLibraryService(this._db);

  final SonoraDatabase _db;

  @override
  Future<List<Song>> getAllSongs({
    bool ascending = true,
    SongSortField? sortBy,
  }) async {
    final entities = await _db.libraryDao.getAllSongs();
    final domainSongs = entities.map((e) => e.toDomain()).toList();
    final sort = sortBy ?? SongSortField.title;

    // Sort
    switch (sort) {
      case SongSortField.title:
        domainSongs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SongSortField.artist:
        domainSongs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SongSortField.album:
        domainSongs.sort((a, b) => a.album.compareTo(b.album));
        break;
      case SongSortField.dateAdded:
        domainSongs.sort(
          (a, b) => (b.dateAdded ?? DateTime(0)).compareTo(
            a.dateAdded ?? DateTime(0),
          ),
        );
        break;
      case SongSortField.playCount:
        domainSongs.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case SongSortField.duration:
        domainSongs.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }
    return domainSongs;
  }

  @override
  Future<List<Album>> getAllAlbums() async {
    final entities = await _db.libraryDao.getAllAlbums();
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Artist>> getAllArtists() async {
    final entities = await _db.libraryDao.getAllArtists();
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Song>> getSongsForAlbum(String albumId) async {
    final entities = await _db.libraryDao.getSongsForAlbum(albumId);
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Song>> getSongsForArtist(String artistId) async {
    final entities = await _db.libraryDao.getSongsForArtist(artistId);
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Song>> getRecentlyPlayed({int limit = 20}) async {
    final entities = await _db.libraryDao.getRecentlyPlayed(limit: limit);
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Song>> getRecentlyAdded({int limit = 20}) async {
    final entities = await _db.libraryDao.getRecentlyAdded(limit: limit);
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Song>> getFavorites() async {
    final entities = await _db.libraryDao.getFavorites();
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Stream<List<Song>> watchFavorites() {
    return _db.libraryDao.watchFavorites().map(
      (entities) => entities.map((e) => e.toDomain()).toList(),
    );
  }

  @override
  Future<void> toggleFavorite(String songId) async {
    await _db.libraryDao.toggleFavorite(songId);
  }

  @override
  Future<void> recordPlay(String songId) async {
    await _db.libraryDao.recordPlay(songId);
  }

  @override
  Future<LibrarySearchResult> search(String query) async {
    // For Phase 2, naive local filtering (could be improved with FTS later)
    final q = query.toLowerCase();

    final allSongs = await _db.libraryDao.getAllSongs();
    final allAlbums = await _db.libraryDao.getAllAlbums();
    final allArtists = await _db.libraryDao.getAllArtists();

    final matchingSongs = allSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.artistName.toLowerCase().contains(q),
        )
        .map((e) => e.toDomain())
        .toList();

    final matchingAlbums = allAlbums
        .where((a) => a.title.toLowerCase().contains(q))
        .map((e) => e.toDomain())
        .toList();

    final matchingArtists = allArtists
        .where((a) => a.name.toLowerCase().contains(q))
        .map((e) => e.toDomain())
        .toList();

    return LibrarySearchResult(
      songs: matchingSongs,
      albums: matchingAlbums,
      artists: matchingArtists,
    );
  }

  @override
  Future<LibraryCounts> getCounts() async {
    final allSongs = await _db.libraryDao.getAllSongs();
    final allAlbums = await _db.libraryDao.getAllAlbums();
    final allArtists = await _db.libraryDao.getAllArtists();
    final allPlaylists = await _db.libraryDao.getAllPlaylists();

    final totalDuration = allSongs.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + Duration(milliseconds: curr.durationMillis),
    );

    return LibraryCounts(
      songs: allSongs.length,
      albums: allAlbums.length,
      artists: allArtists.length,
      playlists: allPlaylists.length,
      totalDuration: totalDuration,
    );
  }

  @override
  Future<void> dispose() async {
    // Nothing specific to dispose here, DB is handled externally
  }

  @override
  Stream<ScanProgress> get scanProgressStream => const Stream.empty();

  @override
  Future<void> addFolder(String path) async {}

  @override
  Future<void> removeFolder(String path) async {}

  @override
  Future<List<String>> getFolders() async => [];

  @override
  Future<void> scanLibrary() async {}

  @override
  Future<void> rescanLibrary() async {}
}
