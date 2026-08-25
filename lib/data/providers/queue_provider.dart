import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song.dart';
import '../../services/audio_player_service.dart';
import 'repository_providers.dart';

class PlaybackStateNotifier extends Notifier<PlaybackState> {
  List<Song> _originalQueue = [];

  @override
  PlaybackState build() {
    return const PlaybackState();
  }

  PlaybackState get currentState => state;

  void updateState(PlaybackState newState) {
    final oldSong = state.currentSong;
    state = newState;

    // Track recently played
    if (newState.currentSong != null &&
        newState.currentSong?.id != oldSong?.id) {
      ref.read(libraryRepositoryProvider).recordPlay(newState.currentSong!.id);
    }
  }

  /// Updates the favorite status of the current song in-memory.
  ///
  /// This does NOT persist to the database — that must be done separately.
  /// Only mutates the in-memory [PlaybackState] so the UI updates instantly.
  void updateCurrentSongFavorite(bool isFavorite) {
    final current = state.currentSong;
    if (current == null) return;

    final updatedSong = current.copyWith(isFavorite: isFavorite);

    // Update the song in the queue list as well
    final updatedQueue = state.queue.map((s) {
      return s.id == current.id ? updatedSong : s;
    }).toList();

    // Update the song in the original queue too
    _originalQueue = _originalQueue.map((s) {
      return s.id == current.id ? updatedSong : s;
    }).toList();

    state = state.copyWith(currentSong: updatedSong, queue: updatedQueue);
  }

  void playQueue(List<Song> queue, {int startIndex = 0}) {
    if (queue.isEmpty) return;
    _originalQueue = List.from(queue);

    state = state.copyWith(
      queue: queue,
      currentIndex: startIndex,
      currentSong: queue[startIndex],
      error: null,
    );
  }

  void addToQueue(Song song) {
    _originalQueue.add(song);
    final newQueue = List<Song>.from(state.queue)..add(song);
    state = state.copyWith(queue: newQueue);
  }

  void addToQueueNext(Song song) {
    final insertIndex = state.currentIndex + 1;
    _originalQueue.insert(insertIndex, song);
    final newQueue = List<Song>.from(state.queue)..insert(insertIndex, song);
    state = state.copyWith(queue: newQueue);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;

    final songToRemove = state.queue[index];
    _originalQueue.remove(songToRemove);

    final newQueue = List<Song>.from(state.queue)..removeAt(index);

    int newIndex = state.currentIndex;
    if (index < newIndex) {
      newIndex--;
    } else if (index == newIndex && newQueue.isNotEmpty) {
      // If we removed the current song, stay at the same index if possible
      newIndex = newIndex.clamp(0, newQueue.length - 1);
    } else if (newQueue.isEmpty) {
      newIndex = -1;
    }

    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
      currentSong: newIndex >= 0 ? newQueue[newIndex] : null,
    );
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.queue.length ||
        newIndex < 0 ||
        newIndex > state.queue.length) {
      return;
    }

    final newQueue = List<Song>.from(state.queue);
    final song = newQueue.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    newQueue.insert(newIndex, song);

    _originalQueue = List.from(newQueue);

    int currentIndex = state.currentIndex;
    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (currentIndex > oldIndex && currentIndex <= newIndex) {
      currentIndex--;
    } else if (currentIndex < oldIndex && currentIndex >= newIndex) {
      currentIndex++;
    }

    state = state.copyWith(queue: newQueue, currentIndex: currentIndex);
  }

  void clearQueue() {
    final current = state.currentSong;
    if (current == null) {
      _originalQueue.clear();
      state = state.copyWith(queue: const [], currentIndex: -1);
    } else {
      _originalQueue = [current];
      state = state.copyWith(queue: [current], currentIndex: 0);
    }
  }

  void toggleShuffle() {
    final willShuffle = !state.shuffleEnabled;
    if (state.queue.isEmpty) {
      state = state.copyWith(shuffleEnabled: willShuffle);
      return;
    }

    final currentSong = state.currentSong;
    List<Song> newQueue;

    if (willShuffle) {
      newQueue = List.from(_originalQueue);
      if (currentSong != null) {
        newQueue.remove(currentSong);
        newQueue.shuffle(Random());
        newQueue.insert(0, currentSong);
      } else {
        newQueue.shuffle(Random());
      }
    } else {
      newQueue = List.from(_originalQueue);
    }

    final newIndex = currentSong != null ? newQueue.indexOf(currentSong) : 0;

    state = state.copyWith(
      shuffleEnabled: willShuffle,
      queue: newQueue,
      currentIndex: newIndex,
    );
  }

  void cycleRepeatMode() {
    final current = state.repeatMode;
    SonoraRepeatMode nextMode;

    switch (current) {
      case SonoraRepeatMode.off:
        nextMode = SonoraRepeatMode.all;
        break;
      case SonoraRepeatMode.all:
        nextMode = SonoraRepeatMode.one;
        break;
      case SonoraRepeatMode.one:
        nextMode = SonoraRepeatMode.off;
        break;
    }

    state = state.copyWith(repeatMode: nextMode);
  }
}
