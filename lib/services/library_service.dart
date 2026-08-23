/// Library service interface.
///
/// Defines the contract for music library scanning, indexing,
/// and metadata management.
library;

import 'package:flutter/foundation.dart';

import '../data/models/album.dart';
import '../data/models/artist.dart';
import '../data/models/song.dart';

/// Progress of a library scan operation.
@immutable
class ScanProgress {
  const ScanProgress({
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.currentFile = '',
    this.isScanning = false,
    this.errors = const [],
  });

  final int totalFiles;
  final int processedFiles;
  final String currentFile;
  final bool isScanning;
  final List<String> errors;

  double get progress => totalFiles > 0 ? processedFiles / totalFiles : 0.0;
}

/// Interface for music library operations.
abstract class LibraryService {
  /// Stream of scan progress updates.
  Stream<ScanProgress> get scanProgressStream;

  /// Add a folder to scan.
  Future<void> addFolder(String path);

  /// Remove a folder from the library.
  Future<void> removeFolder(String path);

  /// Get all scanned folder paths.
  Future<List<String>> getFolders();

  /// Perform a full library scan.
  Future<void> scanLibrary();

  /// Perform an incremental rescan (only changed files).
  Future<void> rescanLibrary();

  /// Get all songs, optionally sorted.
  Future<List<Song>> getAllSongs({
    SongSortField? sortBy,
    bool ascending = true,
  });

  /// Get all albums.
  Future<List<Album>> getAllAlbums();

  /// Get all artists.
  Future<List<Artist>> getAllArtists();

  /// Get songs for a specific album.
  Future<List<Song>> getSongsForAlbum(String albumId);

  /// Get songs for a specific artist.
  Future<List<Song>> getSongsForArtist(String artistId);

  /// Get recently played songs.
  Future<List<Song>> getRecentlyPlayed({int limit = 20});

  /// Get recently added songs.
  Future<List<Song>> getRecentlyAdded({int limit = 20});

  /// Get favorite songs.
  Future<List<Song>> getFavorites();

  /// Toggle favorite status for a song.
  Future<void> toggleFavorite(String songId);

  /// Record that a song was played.
  Future<void> recordPlay(String songId);

  /// Search across songs, albums, and artists.
  Future<LibrarySearchResult> search(String query);

  /// Get total counts for the library.
  Future<LibraryCounts> getCounts();

  /// Dispose resources.
  Future<void> dispose();
}

/// Sort fields for song lists.
enum SongSortField { title, artist, album, dateAdded, playCount, duration }

/// Combined search results.
@immutable
class LibrarySearchResult {
  const LibrarySearchResult({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });

  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;

  bool get isEmpty => songs.isEmpty && albums.isEmpty && artists.isEmpty;
}

/// Library statistics.
@immutable
class LibraryCounts {
  const LibraryCounts({
    this.songs = 0,
    this.albums = 0,
    this.artists = 0,
    this.playlists = 0,
    this.totalDuration = Duration.zero,
  });

  final int songs;
  final int albums;
  final int artists;
  final int playlists;
  final Duration totalDuration;
}
