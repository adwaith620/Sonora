import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/album.dart';
import '../../data/models/artist.dart';
import '../../data/models/song.dart';
import '../../data/providers/repository_providers.dart';

final recentlyPlayedSongsProvider = StreamProvider<List<Song>>((ref) {
  final db = ref.watch(libraryRepositoryProvider);
  return db.watchRecentlyPlayed(limit: 10);
});

final recentlyAddedSongsProvider = StreamProvider<List<Song>>((ref) {
  final db = ref.watch(libraryRepositoryProvider);
  return db.watchRecentlyAdded(limit: 10);
});

final homeAlbumsProvider = StreamProvider<List<Album>>((ref) {
  final db = ref.watch(libraryRepositoryProvider);
  return db.watchAllAlbums();
});

final homeArtistsProvider = StreamProvider<List<Artist>>((ref) {
  final db = ref.watch(libraryRepositoryProvider);
  return db.watchAllArtists();
});
