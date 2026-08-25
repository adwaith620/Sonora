import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../services/playlist_service.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'database.dart';
import 'drift_library_service.dart'; // for SongEntityMapper

extension PlaylistEntityMapper on PlaylistEntity {
  Playlist toDomain(List<String> songIds, {String? artworkPath}) {
    return Playlist(
      id: id,
      name: name,
      songIds: songIds,
      artworkPath: artworkPath,
    );
  }
}

class DriftPlaylistService implements PlaylistService {
  DriftPlaylistService(this._db);

  final SonoraDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final entities = await _db.libraryDao.getAllPlaylists();
    final List<Playlist> results = [];

    for (var entity in entities) {
      final songs = await _db.libraryDao.getSongsForPlaylist(entity.id);
      String? artworkPath;
      if (songs.isNotEmpty) {
        artworkPath = songs.first.artworkPath;
      }
      results.add(
        entity.toDomain(
          songs.map((s) => s.id).toList(),
          artworkPath: artworkPath,
        ),
      );
    }

    return results;
  }

  @override
  Stream<List<Playlist>> watchAllPlaylists() {
    return _db.libraryDao.watchAllPlaylists().asyncMap((entities) async {
      final List<Playlist> results = [];
      for (var entity in entities) {
        final songs = await _db.libraryDao.getSongsForPlaylist(entity.id);
        String? artworkPath;
        if (songs.isNotEmpty) {
          artworkPath = songs.first.artworkPath;
        }
        results.add(
          entity.toDomain(
            songs.map((s) => s.id).toList(),
            artworkPath: artworkPath,
          ),
        );
      }
      return results;
    });
  }

  @override
  Future<Playlist?> getPlaylist(String id) async {
    final entities = await _db.libraryDao.getAllPlaylists();
    try {
      final entity = entities.firstWhere((e) => e.id == id);
      final songs = await _db.libraryDao.getSongsForPlaylist(id);
      return entity.toDomain(
        songs.map((s) => s.id).toList(),
        artworkPath: songs.isNotEmpty ? songs.first.artworkPath : null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<Playlist?> watchPlaylist(String id) {
    return _db.libraryDao.watchPlaylist(id).asyncMap((entity) async {
      if (entity == null) return null;
      final songs = await _db.libraryDao.getSongsForPlaylist(id);
      return entity.toDomain(
        songs.map((s) => s.id).toList(),
        artworkPath: songs.isNotEmpty ? songs.first.artworkPath : null,
      );
    });
  }

  @override
  Future<Playlist> createPlaylist(String name) async {
    final id = _uuid.v4();
    final entity = PlaylistEntity(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.libraryDao.insertPlaylist(entity);
    return entity.toDomain([]);
  }

  @override
  Future<void> renamePlaylist(String id, String newName) async {
    await (_db.update(_db.playlists)..where((t) => t.id.equals(id))).write(
      PlaylistsCompanion(
        name: drift.Value(newName),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> addSong(String playlistId, String songId) async {
    final songs = await _db.libraryDao.getSongsForPlaylist(playlistId);
    final position = songs.length;
    await _db.libraryDao.addSongToPlaylist(playlistId, songId, position);
  }

  @override
  Future<void> removeSong(String playlistId, String songId) async {
    await (_db.delete(_db.playlistSongs)..where(
          (t) => t.playlistId.equals(playlistId) & t.songId.equals(songId),
        ))
        .go();
  }

  @override
  Future<void> reorderSongs(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    // Basic reorder approach: fetch all, adjust order, rewrite
    final songs =
        await (_db.select(_db.playlistSongs)
              ..where((t) => t.playlistId.equals(playlistId))
              ..orderBy([(t) => drift.OrderingTerm.asc(t.position)]))
            .get();

    final target = songs.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    songs.insert(newIndex, target);

    await _db.transaction(() async {
      for (int i = 0; i < songs.length; i++) {
        await (_db.update(_db.playlistSongs)..where(
              (t) =>
                  t.playlistId.equals(playlistId) &
                  t.songId.equals(songs[i].songId),
            ))
            .write(PlaylistSongsCompanion(position: drift.Value(i)));
      }
    });
  }

  @override
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final entities = await _db.libraryDao.getSongsForPlaylist(playlistId);
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Stream<List<Song>> watchPlaylistSongs(String playlistId) {
    return _db.libraryDao
        .watchSongsForPlaylist(playlistId)
        .map((entities) => entities.map((e) => e.toDomain()).toList());
  }

  @override
  Future<Playlist> getFavoritesPlaylist() async {
    // Create a virtual playlist for favorites
    final favs = await _db.libraryDao.getFavorites();
    String? artworkPath;
    if (favs.isNotEmpty) {
      artworkPath = favs.first.artworkPath;
    }
    return Playlist(
      id: 'favorites',
      name: 'Favorites',
      songIds: favs.map((e) => e.id).toList(),
      artworkPath: artworkPath,
    );
  }

  @override
  Future<void> dispose() async {}
}
