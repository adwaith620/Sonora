/// Album data model.
library;

import 'package:flutter/foundation.dart';

/// Represents an album in the music library.
@immutable
class Album {
  const Album({
    required this.id,
    required this.name,
    this.artist = 'Unknown Artist',
    this.year,
    this.artworkPath,
    this.songCount = 0,
    this.totalDuration = Duration.zero,
  });

  final String id;
  final String name;
  final String artist;
  final int? year;
  final String? artworkPath;
  final int songCount;
  final Duration totalDuration;

  Album copyWith({
    String? id,
    String? name,
    String? artist,
    int? year,
    String? artworkPath,
    int? songCount,
    Duration? totalDuration,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      year: year ?? this.year,
      artworkPath: artworkPath ?? this.artworkPath,
      songCount: songCount ?? this.songCount,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Album(id: $id, name: $name, artist: $artist)';
}
