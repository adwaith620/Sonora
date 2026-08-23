/// Audio player service interface.
///
/// Defines the contract for audio playback. The actual implementation
/// will use media_kit in a later phase.
library;

import 'package:flutter/foundation.dart';

/// Repeat mode for the audio player.
enum SonoraRepeatMode { off, all, one }

/// Represents the current state of audio playback.
@immutable
class PlaybackState {
  const PlaybackState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.shuffleEnabled = false,
    this.repeatMode = SonoraRepeatMode.off,
    this.currentIndex = -1,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool shuffleEnabled;
  final SonoraRepeatMode repeatMode;
  final int currentIndex;

  /// Progress as a value between 0.0 and 1.0.
  double get progress => duration.inMilliseconds > 0
      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  PlaybackState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? shuffleEnabled,
    SonoraRepeatMode? repeatMode,
    int? currentIndex,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      currentIndex: currentIndex ?? this.currentIndex,
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

  /// Play a specific file path.
  Future<void> play(String filePath);

  /// Play a list of file paths starting at [index].
  Future<void> playAll(List<String> filePaths, {int startIndex = 0});

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
  void toggleShuffle();

  /// Cycle through repeat modes.
  void cycleRepeatMode();

  /// Add a file path to the end of the queue.
  void addToQueue(String filePath);

  /// Add a file path to play next.
  void addToQueueNext(String filePath);

  /// Remove an item from the queue by index.
  void removeFromQueue(int index);

  /// Reorder an item in the queue.
  void reorderQueue(int oldIndex, int newIndex);

  /// Get the current queue.
  List<String> get queue;

  /// Dispose resources.
  Future<void> dispose();
}
