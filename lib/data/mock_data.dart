/// Mock data for UI development.
///
/// This file provides sample data for the UI shell before the
/// actual library scanner and database are implemented.
library;

import 'models/song.dart';
import 'models/album.dart';
import 'models/artist.dart';
import 'models/playlist.dart';

/// Mock songs for UI development.
final List<Song> mockSongs = [
  Song(
    id: 's1',
    filePath: '/music/album1/track01.flac',
    title: 'Morning Light',
    artist: 'Luna Wave',
    album: 'Daybreak',
    year: 2024,
    trackNumber: 1,
    duration: const Duration(minutes: 3, seconds: 42),
    isFavorite: true,
    playCount: 15,
    dateAdded: DateTime(2024, 6, 15),
    lastPlayedAt: DateTime(2024, 8, 20),
  ),
  Song(
    id: 's2',
    filePath: '/music/album1/track02.flac',
    title: 'Golden Hour',
    artist: 'Luna Wave',
    album: 'Daybreak',
    year: 2024,
    trackNumber: 2,
    duration: const Duration(minutes: 4, seconds: 15),
    isFavorite: false,
    playCount: 8,
    dateAdded: DateTime(2024, 6, 15),
  ),
  Song(
    id: 's3',
    filePath: '/music/album2/track01.mp3',
    title: 'Midnight Drive',
    artist: 'Echo Valley',
    album: 'Neon Roads',
    year: 2023,
    trackNumber: 1,
    duration: const Duration(minutes: 5, seconds: 3),
    isFavorite: true,
    playCount: 23,
    dateAdded: DateTime(2024, 3, 10),
    lastPlayedAt: DateTime(2024, 8, 19),
  ),
  Song(
    id: 's4',
    filePath: '/music/album2/track02.mp3',
    title: 'City Lights',
    artist: 'Echo Valley',
    album: 'Neon Roads',
    year: 2023,
    trackNumber: 2,
    duration: const Duration(minutes: 3, seconds: 58),
    playCount: 5,
    dateAdded: DateTime(2024, 3, 10),
  ),
  Song(
    id: 's5',
    filePath: '/music/album3/track01.flac',
    title: 'Ocean Breeze',
    artist: 'Coastal Drift',
    album: 'Tidal',
    year: 2024,
    trackNumber: 1,
    duration: const Duration(minutes: 6, seconds: 12),
    isFavorite: true,
    playCount: 12,
    dateAdded: DateTime(2024, 7, 1),
    lastPlayedAt: DateTime(2024, 8, 18),
  ),
  Song(
    id: 's6',
    filePath: '/music/album3/track02.flac',
    title: 'Coral Reef',
    artist: 'Coastal Drift',
    album: 'Tidal',
    year: 2024,
    trackNumber: 2,
    duration: const Duration(minutes: 4, seconds: 30),
    playCount: 7,
    dateAdded: DateTime(2024, 7, 1),
  ),
  Song(
    id: 's7',
    filePath: '/music/album4/track01.m4a',
    title: 'Starfall',
    artist: 'Nova Pulse',
    album: 'Cosmos',
    year: 2023,
    trackNumber: 1,
    duration: const Duration(minutes: 4, seconds: 45),
    isFavorite: false,
    playCount: 18,
    dateAdded: DateTime(2024, 1, 20),
    lastPlayedAt: DateTime(2024, 8, 17),
  ),
  Song(
    id: 's8',
    filePath: '/music/album4/track02.m4a',
    title: 'Nebula',
    artist: 'Nova Pulse',
    album: 'Cosmos',
    year: 2023,
    trackNumber: 2,
    duration: const Duration(minutes: 5, seconds: 22),
    playCount: 10,
    dateAdded: DateTime(2024, 1, 20),
  ),
  Song(
    id: 's9',
    filePath: '/music/album5/track01.ogg',
    title: 'Forest Walk',
    artist: 'Timber & Moss',
    album: 'Wilderness',
    year: 2024,
    trackNumber: 1,
    duration: const Duration(minutes: 3, seconds: 15),
    isFavorite: true,
    playCount: 6,
    dateAdded: DateTime(2024, 8, 1),
    lastPlayedAt: DateTime(2024, 8, 21),
  ),
  Song(
    id: 's10',
    filePath: '/music/album5/track02.ogg',
    title: 'River Stone',
    artist: 'Timber & Moss',
    album: 'Wilderness',
    year: 2024,
    trackNumber: 2,
    duration: const Duration(minutes: 4, seconds: 8),
    playCount: 3,
    dateAdded: DateTime(2024, 8, 1),
  ),
];

/// Mock albums for UI development.
final List<Album> mockAlbums = [
  const Album(
    id: 'a1',
    name: 'Daybreak',
    artist: 'Luna Wave',
    year: 2024,
    songCount: 2,
    totalDuration: Duration(minutes: 7, seconds: 57),
  ),
  const Album(
    id: 'a2',
    name: 'Neon Roads',
    artist: 'Echo Valley',
    year: 2023,
    songCount: 2,
    totalDuration: Duration(minutes: 9, seconds: 1),
  ),
  const Album(
    id: 'a3',
    name: 'Tidal',
    artist: 'Coastal Drift',
    year: 2024,
    songCount: 2,
    totalDuration: Duration(minutes: 10, seconds: 42),
  ),
  const Album(
    id: 'a4',
    name: 'Cosmos',
    artist: 'Nova Pulse',
    year: 2023,
    songCount: 2,
    totalDuration: Duration(minutes: 10, seconds: 7),
  ),
  const Album(
    id: 'a5',
    name: 'Wilderness',
    artist: 'Timber & Moss',
    year: 2024,
    songCount: 2,
    totalDuration: Duration(minutes: 7, seconds: 23),
  ),
];

/// Mock artists for UI development.
const List<Artist> mockArtists = [
  Artist(id: 'ar1', name: 'Luna Wave', songCount: 2, albumCount: 1),
  Artist(id: 'ar2', name: 'Echo Valley', songCount: 2, albumCount: 1),
  Artist(id: 'ar3', name: 'Coastal Drift', songCount: 2, albumCount: 1),
  Artist(id: 'ar4', name: 'Nova Pulse', songCount: 2, albumCount: 1),
  Artist(id: 'ar5', name: 'Timber & Moss', songCount: 2, albumCount: 1),
];

/// Mock playlists for UI development.
final List<Playlist> mockPlaylists = [
  Playlist(
    id: 'p_fav',
    name: 'Favorites',
    songIds: const ['s1', 's3', 's5', 's9'],
    isFavorites: true,
    createdAt: DateTime(2024, 1, 1),
  ),
  Playlist(
    id: 'p1',
    name: 'Chill Vibes',
    songIds: const ['s1', 's5', 's6', 's10'],
    createdAt: DateTime(2024, 5, 10),
  ),
  Playlist(
    id: 'p2',
    name: 'Night Drive',
    songIds: const ['s3', 's4', 's7', 's8'],
    createdAt: DateTime(2024, 6, 20),
  ),
];

/// The currently "playing" mock song for the mini player / Now Playing preview.
final Song mockCurrentSong = mockSongs[0];
