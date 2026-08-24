import 'dart:async';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/file_reference.dart';
import '../data/database/database.dart';

import 'scanner_service.dart';

class LocalScannerService implements ScannerService {
  LocalScannerService(this._db) {
    _initArtworkDir();
  }

  final SonoraDatabase _db;
  final _uuid = const Uuid();
  late final Directory _artworkDir;

  ScannerState _state = const ScannerState();
  final _stateController = StreamController<ScannerState>.broadcast();

  bool _isCancelled = false;

  @override
  Stream<ScannerState> get stateStream => _stateController.stream;

  @override
  ScannerState get currentState => _state;

  void _emit(ScannerState state) {
    _state = state;
    _stateController.add(_state);
  }

  Future<void> _initArtworkDir() async {
    final supportDir = await getApplicationSupportDirectory();
    _artworkDir = Directory(p.join(supportDir.path, 'artwork_cache'));
    if (!await _artworkDir.exists()) {
      await _artworkDir.create(recursive: true);
    }
  }

  @override
  void cancelScan() {
    if (_state.status == ScannerStatus.scanning) {
      _isCancelled = true;
      _emit(_state.copyWith(status: ScannerStatus.cancelling));
    }
  }

  @override
  Future<void> scanLibrary() async {
    if (_state.status == ScannerStatus.scanning) return;

    _isCancelled = false;
    _emit(const ScannerState(status: ScannerStatus.scanning));

    try {
      final locations = await _db.libraryDao.getLibraryLocations();
      final enabledLocations = locations.where((l) => l.isEnabled).toList();

      if (enabledLocations.isEmpty) {
        _emit(_state.copyWith(status: ScannerStatus.idle));
        return;
      }

      // Collect existing paths for deletion detection
      final existingPaths = await _db.libraryDao.getAllSongPaths();
      final existingPathsSet = existingPaths.toSet();
      final foundPaths = <String>{};

      int discovered = 0;
      int processed = 0;
      int added = 0;
      int updated = 0;

      // 1. Discovery Phase
      final filesToProcess = <MusicFileReference>[];
      final saf = Saf(); // We'll create instances dynamically as needed

      for (final loc in enabledLocations) {
        if (_isCancelled) break;

        if (Platform.isAndroid && loc.folderUri.startsWith('content://')) {
          // Android SAF
          final stream = saf.walk(loc.folderUri);
          await for (final entry in stream) {
            if (_isCancelled) break;
            if (!entry.file.isDir) {
              final ext = p.extension(entry.file.name).toLowerCase();
              if (kSupportedAudioExtensions.contains(ext)) {
                filesToProcess.add(
                  AndroidSafMusicFileReference(entry.file, saf),
                );
                discovered++;
                if (discovered % 100 == 0) {
                  _emit(_state.copyWith(filesDiscovered: discovered));
                  await Future.delayed(Duration.zero);
                }
              }
            }
          }
        } else {
          // Windows / standard filesystem
          final dir = Directory(loc.folderUri);
          if (await dir.exists()) {
            await for (final entity in dir.list(
              recursive: true,
              followLinks: false,
            )) {
              if (_isCancelled) break;
              if (entity is File) {
                final ext = p.extension(entity.path).toLowerCase();
                if (kSupportedAudioExtensions.contains(ext)) {
                  filesToProcess.add(WindowsMusicFileReference(entity));
                  discovered++;
                  if (discovered % 100 == 0) {
                    _emit(_state.copyWith(filesDiscovered: discovered));
                    // Yield to event loop to keep UI responsive
                    await Future.delayed(Duration.zero);
                  }
                }
              }
            }
          }
        }
      }

      _emit(_state.copyWith(filesDiscovered: discovered));

      // 2. Processing Phase
      for (final file in filesToProcess) {
        if (_isCancelled) break;

        foundPaths.add(file.uri);
        processed++;

        if (processed % 10 == 0) {
          _emit(
            _state.copyWith(filesProcessed: processed, currentFile: file.name),
          );
          await Future.delayed(Duration.zero); // Keep UI responsive
        }

        try {
          final isNew = !existingPathsSet.contains(file.uri);
          final fileSize = await file.getSize();

          if (!isNew) {
            // Check if file has been modified
            final existingSong = await _db.libraryDao.getSongByPath(file.uri);
            if (existingSong != null && existingSong.fileSize == fileSize) {
              // Unchanged, skip expensive metadata extraction
              continue;
            }
          }

          // Extract metadata
          final metadata = await file.withFile((f) async {
            return readMetadata(f, getImage: true);
          });

          // Fallbacks
          final title = metadata.title ?? p.basenameWithoutExtension(file.name);
          final artistName = metadata.artist ?? 'Unknown Artist';
          final albumName = metadata.album ?? 'Unknown Album';
          final durationMillis = metadata.duration?.inMilliseconds ?? 0;
          final genre = metadata.genres.isNotEmpty
              ? metadata.genres.first
              : null;
          final year = metadata.year?.year;
          final trackNumber = metadata.trackNumber;
          final discNumber = metadata.discNumber;

          // Artwork
          String? artworkPath;
          if (metadata.pictures.isNotEmpty) {
            final pic = metadata.pictures.first;
            // Use SHA256 of bytes for deduplication
            final hash = sha256.convert(pic.bytes).toString();
            final ext = _getExtensionFromMimeType(pic.mimetype);
            final cachedFile = File(p.join(_artworkDir.path, '$hash$ext'));

            if (!await cachedFile.exists()) {
              await cachedFile.writeAsBytes(pic.bytes);
            }
            artworkPath = cachedFile.path;
          }

          // Artist resolution
          ArtistEntity? artistEntity = await _db.libraryDao.getArtistByName(
            artistName,
          );
          if (artistEntity == null) {
            artistEntity = ArtistEntity(
              id: _uuid.v4(),
              name: artistName,
              artworkPath: null, // Artist artwork usually requires network, which we avoid in this phase
            );
            await _db.libraryDao.insertArtist(artistEntity);
          }

          // Album resolution
          AlbumEntity? albumEntity = await _db.libraryDao
              .getAlbumByTitleAndArtist(albumName, artistEntity.id);
          if (albumEntity == null) {
            albumEntity = AlbumEntity(
              id: _uuid.v4(),
              title: albumName,
              artistId: artistEntity.id,
              albumArtist: artistName,
              year: year,
              artworkPath: artworkPath,
            );
            await _db.libraryDao.insertAlbum(albumEntity);
          } else if (albumEntity.artworkPath == null && artworkPath != null) {
            // Update album with artwork if it didn't have one
            albumEntity = albumEntity.copyWith(artworkPath: Value(artworkPath));
            await _db.libraryDao.insertAlbum(albumEntity);
          }

          // Song creation/update
          final existingSong = isNew
              ? null
              : await _db.libraryDao.getSongByPath(file.uri);
          final songId = existingSong?.id ?? _uuid.v4();

          final songEntity = SongEntity(
            id: songId,
            fileUri: file.uri,
            title: title,
            artistId: artistEntity.id,
            albumId: albumEntity.id,
            artistName: artistName,
            albumName: albumName,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            durationMillis: durationMillis,
            artworkPath: artworkPath,
            playCount: existingSong?.playCount ?? 0,
            lastPlayedAt: existingSong?.lastPlayedAt,
            dateAdded: existingSong?.dateAdded ?? DateTime.now(),
            fileSize: fileSize,
            isFavorite: existingSong?.isFavorite ?? false,
          );

          await _db.libraryDao.insertSong(songEntity);

          if (isNew) {
            added++;
          } else {
            updated++;
          }
        } catch (e) {
          debugPrint('Error processing file ${file.uri}: $e');
          // Don't crash, continue with other files
        }
      }

      // 3. Cleanup Phase (Missing Files)
      int removed = 0;
      if (!_isCancelled) {
        final missingPaths = existingPathsSet.difference(foundPaths).toList();
        if (missingPaths.isNotEmpty) {
          await _db.libraryDao.removeSongsByPaths(missingPaths);
          removed = missingPaths.length;
        }
      }

      _emit(
        _state.copyWith(
          status: _isCancelled
              ? ScannerStatus.idle
              : ScannerStatus.idle, // Go back to idle when done
          filesProcessed: processed,
          filesAdded: added,
          filesUpdated: updated,
          filesRemoved: removed,
          currentFile: null,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          status: ScannerStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  String _getExtensionFromMimeType(String mime) {
    if (mime.contains('png')) return '.png';
    if (mime.contains('gif')) return '.gif';
    if (mime.contains('webp')) return '.webp';
    return '.jpg'; // default
  }
}
