import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';
import 'audio_player_service.dart';

/// Integrates Sonora with the Android OS background audio service.
class SonoraAudioHandler extends BaseAudioHandler with SeekHandler {
  // We'll set this from MediaKitAudioService after initialization
  AudioPlayerService? audioService;

  void broadcastState(PlaybackState state) {
    final playing = state.isPlaying;
    
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: state.position,
      bufferedPosition: state.bufferedPosition,
      speed: 1.0,
      queueIndex: state.currentIndex,
    ));

    if (state.currentSong != null) {
      final song = state.currentSong!;
      mediaItem.add(MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
      ));
    }
  }

  @override
  Future<void> play() async => await audioService?.resume();

  @override
  Future<void> pause() async => await audioService?.pause();

  @override
  Future<void> stop() async => await audioService?.stop();

  @override
  Future<void> seek(Duration position) async => await audioService?.seek(position);

  @override
  Future<void> skipToNext() async => await audioService?.next();

  @override
  Future<void> skipToPrevious() async => await audioService?.previous();
  
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await audioService?.toggleShuffle();
  }
}
