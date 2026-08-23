/// Playlist data model.
library;

import 'package:flutter/foundation.dart';

/// Represents a user-created playlist.
@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.songIds = const [],
    this.artworkPath,
    this.createdAt,
    this.updatedAt,
    this.isFavorites = false,
  });

  final String id;
  final String name;
  final List<String> songIds;
  final String? artworkPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether this is the auto-generated Favorites playlist.
  final bool isFavorites;

  int get songCount => songIds.length;

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    String? artworkPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorites,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      artworkPath: artworkPath ?? this.artworkPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorites: isFavorites ?? this.isFavorites,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Playlist(id: $id, name: $name, songs: $songCount)';
}
