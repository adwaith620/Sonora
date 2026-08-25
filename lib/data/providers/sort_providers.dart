import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/library_service.dart';

// Currently LibraryService only has SongSortField enum.
// For Albums and Artists, we'll do in-memory sorting in the providers for simplicity,
// since the Roadmap doesn't require deep database-level complex sorting for those yet,
// and `getAllAlbums` returns a list we can sort.

enum AlbumSortField { title, artist, year }

enum ArtistSortField { name }

final songsSortProvider = StateProvider<SongSortField>(
  (ref) => SongSortField.title,
);
final albumsSortProvider = StateProvider<AlbumSortField>(
  (ref) => AlbumSortField.title,
);
final artistsSortProvider = StateProvider<ArtistSortField>(
  (ref) => ArtistSortField.name,
);

// We need a provider that actually watches songs/albums/artists and sorts them.
// But wait, songsListProvider is in `songs_screen.dart`, etc.
