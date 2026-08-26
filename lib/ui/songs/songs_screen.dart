import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/constants.dart';
import '../../data/models/song.dart';
import '../../data/providers/audio_provider.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/sort_providers.dart';
import '../../services/library_service.dart';
import '../../theme/dimensions.dart';
import '../common/alphabetical_scroll_bar.dart';
import '../common/artwork_widget.dart';

final songsListProvider = FutureProvider<List<Song>>((ref) async {
  final db = ref.watch(libraryRepositoryProvider);
  final sort = ref.watch(songsSortProvider);
  return db.getAllSongs(sortBy: sort);
});

final songsLettersProvider = Provider<List<String>>((ref) {
  final songsAsync = ref.watch(songsListProvider);
  return songsAsync.maybeWhen(
    data: (songs) {
      final Set<String> letters = {};
      for (final song in songs) {
        if (song.title.isNotEmpty) {
          final firstChar = song.title[0].toUpperCase();
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

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  final ScrollController _scrollController = ScrollController();
  final double _itemHeight = 72.0;

  void _scrollToLetter(String letter, List<Song> songs) {
    int index = -1;
    if (letter == '#') {
      index = 0;
    } else {
      index = songs.indexWhere((s) => s.title.toUpperCase().startsWith(letter));
    }

    if (index != -1) {
      // 152 for large app bar max height + 64 for the buttons row
      final offset = 152.0 + 64.0 + (index * _itemHeight);
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
    final audioService = ref.read(audioPlayerServiceProvider);
    final songsAsync = ref.watch(songsListProvider);
    final currentSort = ref.watch(songsSortProvider);

    return Scaffold(
      body: Stack(
        children: [
          AnimationLimiter(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar.large(
                  title: const Text('Songs'),
                  actions: [
                    PopupMenuButton<SongSortField>(
                      icon: const Icon(Icons.sort_rounded),
                      initialValue: currentSort,
                      onSelected: (sort) {
                        ref.read(songsSortProvider.notifier).state = sort;
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SongSortField.title,
                          child: Text('Sort by Title'),
                        ),
                        const PopupMenuItem(
                          value: SongSortField.artist,
                          child: Text('Sort by Artist'),
                        ),
                        const PopupMenuItem(
                          value: SongSortField.album,
                          child: Text('Sort by Album'),
                        ),
                        const PopupMenuItem(
                          value: SongSortField.dateAdded,
                          child: Text('Sort by Date Added'),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
                songsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error: $err')),
                  ),
                  data: (songs) {
                    if (songs.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No music found. Add a folder in Settings.',
                          ),
                        ),
                      );
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 64,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                                vertical: Spacing.sm,
                              ),
                              child: Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () {
                                      audioService.playQueue(songs);
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: const Text('Play All'),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      audioService.playQueue(songs);
                                      audioService.toggleShuffle();
                                    },
                                    icon: const Icon(Icons.shuffle_rounded),
                                    label: const Text('Shuffle'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(
                            bottom: kMiniPlayerHeight + Spacing.md,
                          ),
                          sliver: SliverFixedExtentList(
                            itemExtent: _itemHeight,
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final song = songs[index];
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
                                          artworkPath: song.artworkPath,
                                          size: kArtworkThumbnailSize,
                                          borderRadius: BorderRadius.circular(
                                            Spacing.xs,
                                          ),
                                        ),
                                        title: Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.more_vert_rounded,
                                          ),
                                          onPressed: () {},
                                        ),
                                        onTap: () {
                                          audioService.playQueue(
                                            songs,
                                            startIndex: index,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: songs.length),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Alphabetical Scroll Bar overlay
          if (songsAsync.hasValue &&
              songsAsync.value!.isNotEmpty &&
              currentSort == SongSortField.title)
            Positioned(
              top: 160,
              right: 0,
              bottom: kMiniPlayerHeight + 16,
              child: AlphabeticalScrollBar(
                letters: ref.watch(songsLettersProvider),
                onLetterTapped: (letter) {
                  _scrollToLetter(letter, songsAsync.value!);
                },
              ),
            ),
        ],
      ),
    );
  }
}
