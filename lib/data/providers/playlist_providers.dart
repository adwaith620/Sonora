import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import 'repository_providers.dart';

final userPlaylistsProvider = StreamProvider<List<Playlist>>((ref) {
  final playlistService = ref.watch(playlistRepositoryProvider);
  return playlistService.watchAllPlaylists();
});

final playlistProvider = StreamProvider.family<Playlist?, String>((ref, id) {
  if (id == 'smart_recently_played' ||
      id == 'smart_recently_added' ||
      id == 'smart_favorites') {
    return ref
        .watch(smartPlaylistsProvider)
        .whenData(
          (list) =>
              list.firstWhere((p) => p.id == id, orElse: () => null as dynamic),
        )
        .when(
          data: (data) => Stream.value(data),
          error: (e, st) => Stream.error(e, st),
          loading: () => const Stream.empty(),
        );
  }
  final playlistService = ref.watch(playlistRepositoryProvider);
  return playlistService.watchPlaylist(id);
});

final playlistSongsProvider = StreamProvider.family<List<Song>, String>((
  ref,
  id,
) {
  if (id == 'smart_recently_played') {
    return ref.watch(libraryRepositoryProvider).watchRecentlyPlayed(limit: 50);
  } else if (id == 'smart_recently_added') {
    return ref.watch(libraryRepositoryProvider).watchRecentlyAdded(limit: 50);
  } else if (id == 'smart_favorites') {
    return ref.watch(libraryRepositoryProvider).watchFavorites();
  }

  final playlistService = ref.watch(playlistRepositoryProvider);
  return playlistService.watchPlaylistSongs(id);
});

final favoritesSongsProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(libraryRepositoryProvider).watchFavorites();
});

final recentlyPlayedSongsProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(libraryRepositoryProvider).watchRecentlyPlayed(limit: 50);
});

final recentlyAddedSongsProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(libraryRepositoryProvider).watchRecentlyAdded(limit: 50);
});

final smartPlaylistsProvider = Provider<AsyncValue<List<Playlist>>>((ref) {
  final favsAsync = ref.watch(favoritesSongsProvider);
  final playedAsync = ref.watch(recentlyPlayedSongsProvider);
  final addedAsync = ref.watch(recentlyAddedSongsProvider);

  if (favsAsync.isLoading || playedAsync.isLoading || addedAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (favsAsync.hasError) {
    return AsyncValue.error(favsAsync.error!, favsAsync.stackTrace!);
  }
  if (playedAsync.hasError) {
    return AsyncValue.error(playedAsync.error!, playedAsync.stackTrace!);
  }
  if (addedAsync.hasError) {
    return AsyncValue.error(addedAsync.error!, addedAsync.stackTrace!);
  }

  final favs = favsAsync.value!;
  final played = playedAsync.value!;
  final added = addedAsync.value!;

  return AsyncValue.data([
    Playlist(
      id: 'smart_favorites',
      name: 'Favorites',
      songIds: favs.map((e) => e.id).toList(),
      artworkPath: favs.isNotEmpty ? favs.first.artworkPath : null,
      isFavorites: true,
    ),
    Playlist(
      id: 'smart_recently_played',
      name: 'Recently Played',
      songIds: played.map((e) => e.id).toList(),
      artworkPath: played.isNotEmpty ? played.first.artworkPath : null,
    ),
    Playlist(
      id: 'smart_recently_added',
      name: 'Recently Added',
      songIds: added.map((e) => e.id).toList(),
      artworkPath: added.isNotEmpty ? added.first.artworkPath : null,
    ),
  ]);
});
