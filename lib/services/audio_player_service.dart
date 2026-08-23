/// Audio player service interface.
///
/// Defines the contract for audio playback. The actual implementation
/// will use media_kit in a later phase.
library;

import 'package:flutter/foundation.dart';
import '../data/models/song.dart';

/// Repeat mode for the audio player.
enum SonoraRepeatMode { off, all, one }

/// Represents the current state of audio playback.
@immutable
class PlaybackState {
  const PlaybackState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.shuffleEnabled = false,
    this.repeatMode = SonoraRepeatMode.off,
    this.queue = const [],
    this.currentIndex = -1,
    this.error,
  });

  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final bool shuffleEnabled;
  final SonoraRepeatMode repeatMode;
  final List<Song> queue;
  final int currentIndex;
  final String? error;

  /// Progress as a value between 0.0 and 1.0.
  double get progress => duration.inMilliseconds > 0
      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  PlaybackState copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    bool? shuffleEnabled,
    SonoraRepeatMode? repeatMode,
    List<Song>? queue,
    int? currentIndex,
    String? error,
  }) {
    return PlaybackState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error ?? this.error,
    );
  }
}

/// Interface for audio playback operations.
///
/// Implementations should handle platform-specific audio playback
/// (media_kit on both Android and Windows).
abstract class AudioPlayerService {
  /// Stream of playback state changes.
  Stream<PlaybackState> get playbackStateStream;

  /// Current playback state.
  PlaybackState get currentState;

  /// Initialize the audio service.
  Future<void> init();

  /// Play a specific song and optionally replace the queue.
  Future<void> playSong(Song song, {List<Song>? queue});

  /// Play a list of songs starting at [startIndex].
  Future<void> playQueue(List<Song> queue, {int startIndex = 0});

  /// Pause playback.
  Future<void> pause();

  /// Resume playback.
  Future<void> resume();

  /// Toggle play/pause.
  Future<void> togglePlayPause();

  /// Stop playback and reset.
  Future<void> stop();

  /// Seek to a position.
  Future<void> seek(Duration position);

  /// Skip to the next track in the queue.
  Future<void> next();

  /// Skip to the previous track in the queue.
  Future<void> previous();

  /// Set the volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Toggle shuffle mode.
  Future<void> toggleShuffle();

  /// Cycle through repeat modes.
  Future<void> cycleRepeatMode();

  /// Add a song to the end of the queue.
  Future<void> addToQueue(Song song);

  /// Add a song to play next.
  Future<void> addToQueueNext(Song song);

  /// Remove an item from the queue by index.
  Future<void> removeFromQueue(int index);

  /// Reorder an item in the queue.
  Future<void> reorderQueue(int oldIndex, int newIndex);

  /// Clear the queue (leaves current song playing if any).
  Future<void> clearQueue();

  /// Dispose resources.
  Future<void> dispose();
}
