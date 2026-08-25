/// Playlist service interface.
///
/// Defines the contract for playlist management operations.
library;

import '../data/models/playlist.dart';
import '../data/models/song.dart';

/// Interface for playlist operations.
abstract class PlaylistService {
  /// Get all playlists.
  Future<List<Playlist>> getAllPlaylists();

  /// Watch all playlists as a stream.
  Stream<List<Playlist>> watchAllPlaylists();

  /// Get a playlist by ID.
  Future<Playlist?> getPlaylist(String id);

  /// Watch a single playlist as a stream.
  Stream<Playlist?> watchPlaylist(String id);

  /// Create a new playlist.
  Future<Playlist> createPlaylist(String name);

  /// Rename a playlist.
  Future<void> renamePlaylist(String id, String newName);

  /// Delete a playlist.
  Future<void> deletePlaylist(String id);

  /// Add a song to a playlist.
  Future<void> addSong(String playlistId, String songId);

  /// Remove a song from a playlist.
  Future<void> removeSong(String playlistId, String songId);

  /// Reorder songs in a playlist.
  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex);

  /// Get songs in a playlist.
  Future<List<Song>> getPlaylistSongs(String playlistId);

  /// Watch songs in a playlist as a stream.
  Stream<List<Song>> watchPlaylistSongs(String playlistId);

  /// Get the favorites playlist (auto-created).
  Future<Playlist> getFavoritesPlaylist();

  /// Dispose resources.
  Future<void> dispose();
}
