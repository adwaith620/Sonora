/// Artist data model.
library;

import 'package:flutter/foundation.dart';

/// Represents an artist in the music library.
@immutable
class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.artworkPath,
    this.songCount = 0,
    this.albumCount = 0,
  });

  final String id;
  final String name;
  final String? artworkPath;
  final int songCount;
  final int albumCount;

  Artist copyWith({
    String? id,
    String? name,
    String? artworkPath,
    int? songCount,
    int? albumCount,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      artworkPath: artworkPath ?? this.artworkPath,
      songCount: songCount ?? this.songCount,
      albumCount: albumCount ?? this.albumCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Artist(id: $id, name: $name)';
}
