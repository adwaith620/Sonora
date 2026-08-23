/// Song data model.
library;

import 'package:flutter/foundation.dart';

/// Represents a single audio track in the library.
@immutable
class Song {
  const Song({
    required this.id,
    required this.fileUri,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.duration = Duration.zero,
    this.artworkPath,
    this.playCount = 0,
    this.lastPlayedAt,
    this.dateAdded,
    this.fileSize = 0,
    this.isFavorite = false,
  });

  final String id;
  final String fileUri;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final Duration duration;
  final String? artworkPath;
  final int playCount;
  final DateTime? lastPlayedAt;
  final DateTime? dateAdded;
  final int fileSize;
  final bool isFavorite;

  /// Display artist — uses albumArtist if available, falls back to artist.
  String get displayArtist => albumArtist ?? artist;

  Song copyWith({
    String? id,
    String? fileUri,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    Duration? duration,
    String? artworkPath,
    int? playCount,
    DateTime? lastPlayedAt,
    DateTime? dateAdded,
    int? fileSize,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      fileUri: fileUri ?? this.fileUri,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      dateAdded: dateAdded ?? this.dateAdded,
      fileSize: fileSize ?? this.fileSize,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}
