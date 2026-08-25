import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/data/models/song.dart';
import 'package:sonora/data/providers/audio_provider.dart';
import 'package:sonora/services/audio_player_service.dart';

void main() {
  group('PlaybackStateNotifier Queue Logic', () {
    late ProviderContainer container;

    const song1 = Song(id: '1', fileUri: 'test1.mp3', title: 'Song 1');
    const song2 = Song(id: '2', fileUri: 'test2.mp3', title: 'Song 2');
    const song3 = Song(id: '3', fileUri: 'test3.mp3', title: 'Song 3');

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is correct', () {
      final state = container.read(playbackStateNotifierProvider);
      expect(state.queue, isEmpty);
      expect(state.currentIndex, -1);
      expect(state.isPlaying, isFalse);
    });

    test('playQueue sets the queue and current index', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      notifier.playQueue([song1, song2, song3], startIndex: 1);

      final state = container.read(playbackStateNotifierProvider);
      expect(state.queue.length, 3);
      expect(state.currentIndex, 1);
      expect(state.currentSong, song2);
    });

    test('addToQueue appends to the end', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      notifier.playQueue([song1]);
      notifier.addToQueue(song2);

      final state = container.read(playbackStateNotifierProvider);
      expect(state.queue.length, 2);
      expect(state.queue.last, song2);
      expect(state.currentIndex, 0);
    });

    test('addToQueueNext inserts after current', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      notifier.playQueue([song1, song3], startIndex: 0);
      notifier.addToQueueNext(song2);

      final state = container.read(playbackStateNotifierProvider);
      expect(state.queue.length, 3);
      expect(state.queue[1], song2);
      expect(state.queue[2], song3);
    });

    test('removeFromQueue removes correct item and adjusts index', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      notifier.playQueue([song1, song2, song3], startIndex: 1); // playing song2

      // Remove song1 (before current)
      notifier.removeFromQueue(0);
      var state = container.read(playbackStateNotifierProvider);
      expect(state.queue.length, 2);
      expect(state.currentIndex, 0); // index shifted down
      expect(state.currentSong, song2);

      // Remove the currently playing song
      notifier.removeFromQueue(0);
      state = container.read(playbackStateNotifierProvider);
      expect(state.queue.length, 1);
      expect(state.currentIndex, 0); // index stays clamped
      expect(state.currentSong, song3);
    });

    test('reorderQueue moves items and adjusts index correctly', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      notifier.playQueue([song1, song2, song3], startIndex: 1); // playing song2

      // Move song3 to front
      notifier.reorderQueue(2, 0);
      var state = container.read(playbackStateNotifierProvider);
      expect(state.queue, [song3, song1, song2]);
      expect(state.currentIndex, 2); // song2 moved from index 1 to 2

      // Move currently playing song2 to middle
      notifier.reorderQueue(2, 1);
      state = container.read(playbackStateNotifierProvider);
      expect(state.queue, [song3, song2, song1]);
      expect(state.currentIndex, 1);
    });

    test('toggleShuffle maintains current song but randomizes rest', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      notifier.playQueue([song1, song2, song3], startIndex: 1); // playing song2

      notifier.toggleShuffle();
      var state = container.read(playbackStateNotifierProvider);
      expect(state.shuffleEnabled, isTrue);
      expect(state.queue.length, 3);
      expect(state.currentSong, song2);
      expect(
        state.currentIndex,
        0,
      ); // Current song moves to index 0 when shuffled

      notifier.toggleShuffle();
      state = container.read(playbackStateNotifierProvider);
      expect(state.shuffleEnabled, isFalse);
      expect(state.queue, [song1, song2, song3]); // Original queue restored
      expect(state.currentIndex, 1); // Index restored
    });

    test('cycleRepeatMode transitions correctly', () {
      final notifier = container.read(playbackStateNotifierProvider.notifier);
      var state = container.read(playbackStateNotifierProvider);
      expect(state.repeatMode, SonoraRepeatMode.off);

      notifier.cycleRepeatMode();
      state = container.read(playbackStateNotifierProvider);
      expect(state.repeatMode, SonoraRepeatMode.all);

      notifier.cycleRepeatMode();
      state = container.read(playbackStateNotifierProvider);
      expect(state.repeatMode, SonoraRepeatMode.one);

      notifier.cycleRepeatMode();
      state = container.read(playbackStateNotifierProvider);
      expect(state.repeatMode, SonoraRepeatMode.off);
    });
  });
}
