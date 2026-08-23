import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../database/drift_library_service.dart';
import '../database/drift_playlist_service.dart';
import '../../services/library_service.dart';
import '../../services/playlist_service.dart';

/// Provider for the Drift Database instance.
final databaseProvider = Provider<SonoraDatabase>((ref) {
  final db = SonoraDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for the LibraryRepository (currently DriftLibraryService).
final libraryRepositoryProvider = Provider<LibraryService>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftLibraryService(db);
});

/// Provider for the PlaylistRepository (currently DriftPlaylistService).
final playlistRepositoryProvider = Provider<PlaylistService>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftPlaylistService(db);
});
