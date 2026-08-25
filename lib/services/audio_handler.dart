import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'audio_player_service.dart' as sonora;

/// Integrates Sonora with the Android OS background audio service.
class SonoraAudioHandler extends BaseAudioHandler with SeekHandler {
  SonoraAudioHandler() {
    _setupAudioSession();
  }

  // We'll set this from MediaKitAudioService after initialization
  sonora.AudioPlayerService? audioService;

  Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Media_kit handles ducking if configured, but we can set volume manually if needed.
            // For now, pausing on focus loss is safer for a music player.
            pause();
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Restore volume if we had ducked
            break;
          case AudioInterruptionType.pause:
            // Could resume if we want to auto-resume after a call
            // play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  void broadcastState(sonora.PlaybackState state) {
    final playing = state.isPlaying;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: state.currentSong == null
            ? AudioProcessingState.idle
            : AudioProcessingState.ready,
        playing: playing,
        updatePosition: state.position,
        bufferedPosition: state.bufferedPosition,
        speed: 1.0,
        queueIndex: state.currentIndex,
      ),
    );

    if (state.currentSong != null) {
      final song = state.currentSong!;
      mediaItem.add(
        MediaItem(
          id: song.id,
          album: song.album,
          title: song.title,
          artist: song.artist,
          duration: song.duration,
          artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
        ),
      );
    }
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    await session.setActive(true);
    await audioService?.resume();
  }

  @override
  Future<void> pause() async {
    await audioService?.pause();
  }

  @override
  Future<void> stop() async {
    await audioService?.stop();
    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.idle),
    );
  }

  @override
  Future<void> seek(Duration position) async =>
      await audioService?.seek(position);

  @override
  Future<void> skipToNext() async => await audioService?.next();

  @override
  Future<void> skipToPrevious() async => await audioService?.previous();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await audioService?.toggleShuffle();
  }

  @override
  Future<void> onTaskRemoved() async {
    await audioService?.pause();
    await stop();
    await super.onTaskRemoved();
  }
}
