import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/audio_provider.dart';
import '../../theme/dimensions.dart';
import '../common/song_list_tile.dart';

/// A modal bottom sheet that displays and manages the current playback queue.
class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackStateNotifierProvider);
    final audio = ref.read(audioPlayerServiceProvider);
    final queue = state.queue;
    final currentIndex = state.currentIndex;
    final theme = Theme.of(context);

    if (queue.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('Queue is empty', style: theme.textTheme.titleMedium),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Up Next',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  audio.clearQueue();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: Spacing.xxl),
            itemCount: queue.length,
            onReorder: (oldIndex, newIndex) {
              audio.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final song = queue[index];
              final isCurrent = index == currentIndex;

              // Use a stable key that includes index as a fallback for duplicates
              // Since ReorderableListView needs keys to swap appropriately,
              // unique items work best.
              final key = ValueKey('${song.id}_$index');

              return Dismissible(
                key: key,
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  audio.removeFromQueue(index);
                },
                background: Container(
                  color: theme.colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: Spacing.xl),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                child: SongListTile(
                  song: song,
                  isPlaying: isCurrent,
                  onTap: () {
                    audio.playQueue(queue, startIndex: index);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          audio.removeFromQueue(index);
                        },
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
                          child: Icon(Icons.drag_handle_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
