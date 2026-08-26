import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/constants.dart';
import '../../data/models/artist.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/sort_providers.dart';
import '../../theme/dimensions.dart';
import '../common/alphabetical_scroll_bar.dart';
import '../common/artwork_widget.dart';

final artistsListProvider = FutureProvider<List<Artist>>((ref) async {
  final db = ref.watch(libraryRepositoryProvider);
  final sort = ref.watch(artistsSortProvider);
  final artists = await db.getAllArtists();

  switch (sort) {
    case ArtistSortField.name:
      artists.sort((a, b) => a.name.compareTo(b.name));
      break;
  }
  return artists;
});

final artistsLettersProvider = Provider<List<String>>((ref) {
  final artistsAsync = ref.watch(artistsListProvider);
  return artistsAsync.maybeWhen(
    data: (artists) {
      final Set<String> letters = {};
      for (final artist in artists) {
        if (artist.name.isNotEmpty) {
          final firstChar = artist.name[0].toUpperCase();
          if (RegExp(r'[A-Z]').hasMatch(firstChar)) {
            letters.add(firstChar);
          } else {
            letters.add('#');
          }
        }
      }
      return letters.toList()..sort();
    },
    orElse: () => [],
  );
});

class ArtistsScreen extends ConsumerStatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ConsumerState<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends ConsumerState<ArtistsScreen> {
  final ScrollController _scrollController = ScrollController();
  final double _itemHeight = 72.0;

  void _scrollToLetter(String letter, List<Artist> artists) {
    int index = -1;
    if (letter == '#') {
      index = 0;
    } else {
      index = artists.indexWhere(
        (a) => a.name.toUpperCase().startsWith(letter),
      );
    }

    if (index != -1) {
      final offset = (index * _itemHeight);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(artistsListProvider);
    final currentSort = ref.watch(artistsSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists'),
        actions: [
          PopupMenuButton<ArtistSortField>(
            icon: const Icon(Icons.sort_rounded),
            initialValue: currentSort,
            onSelected: (sort) {
              ref.read(artistsSortProvider.notifier).state = sort;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ArtistSortField.name,
                child: Text('Sort by Name'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: artistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (artists) {
          if (artists.isEmpty) {
            return const Center(child: Text('No artists found.'));
          }
          return Stack(
            children: [
              AnimationLimiter(
                child: ListView.builder(
                  controller: _scrollController,
                  itemExtent: _itemHeight,
                  padding: const EdgeInsets.only(
                    bottom: kMiniPlayerHeight + Spacing.md,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: SizedBox(
                            height: _itemHeight,
                            child: ListTile(
                              leading: ArtworkWidget(
                                artworkPath: artist.artworkPath,
                                size: 48,
                                borderRadius: BorderRadius.circular(24),
                                icon: Icons.person_rounded,
                              ),
                              title: Text(
                                artist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed('/artist', arguments: artist.id);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (currentSort == ArtistSortField.name)
                Positioned(
                  top: Spacing.md,
                  right: 0,
                  bottom: kMiniPlayerHeight + 16,
                  child: AlphabeticalScrollBar(
                    letters: ref.watch(artistsLettersProvider),
                    onLetterTapped: (letter) {
                      _scrollToLetter(letter, artists);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
