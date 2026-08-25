import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/albums/album_detail_screen.dart';
import '../ui/albums/albums_screen.dart';
import '../ui/artists/artist_detail_screen.dart';
import '../ui/artists/artists_screen.dart';
import '../ui/favorites/favorites_screen.dart';
import '../ui/folders/folders_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/playlists/playlist_detail_screen.dart';
import '../ui/playlists/playlists_screen.dart';
import '../ui/search/search_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/songs/songs_screen.dart';
import 'app_shell.dart';

/// Route paths.
abstract final class Routes {
  static const String home = '/';
  static const String songs = '/songs';
  static const String albums = '/albums';
  static const String albumDetail = '/albums/:id';
  static const String artists = '/artists';
  static const String artistDetail = '/artists/:id';
  static const String playlists = '/playlists';
  static const String folders = '/folders';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String search = '/search';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Creates the GoRouter instance for Sonora.
GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.home,
    routes: [
      // Main shell with bottom nav / nav rail
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            child: navigationShell,
          );
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Songs tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.songs,
                builder: (context, state) => const SongsScreen(),
              ),
            ],
          ),
          // Albums tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.albums,
                builder: (context, state) => const AlbumsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        AlbumDetailScreen(albumId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // Artists tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.artists,
                builder: (context, state) => const ArtistsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ArtistDetailScreen(
                      artistId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Playlists tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.playlists,
                builder: (context, state) => const PlaylistsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => PlaylistDetailScreen(
                      playlistId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (outside the shell)
      GoRoute(
        path: Routes.folders,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FoldersScreen(),
      ),
      GoRoute(
        path: Routes.favorites,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
}
