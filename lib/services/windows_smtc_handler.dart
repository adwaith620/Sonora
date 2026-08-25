import 'dart:async';
import 'dart:io';

import 'package:smtc_windows/smtc_windows.dart';

import 'audio_player_service.dart';

class SonoraWindowsSMTCHandler {
  SonoraWindowsSMTCHandler() {
    if (!Platform.isWindows) return;
    _init();
  }

  AudioPlayerService? audioService;
  SMTCWindows? _smtc;
  StreamSubscription? _buttonSubscription;

  Future<void> _init() async {
    try {
      _smtc = SMTCWindows(
        config: const SMTCConfig(
          fastForwardEnabled: false,
          nextEnabled: true,
          pauseEnabled: true,
          playEnabled: true,
          prevEnabled: true,
          rewindEnabled: false,
          stopEnabled: true,
        ),
      );

      _buttonSubscription = _smtc?.buttonPressStream.listen((event) {
        switch (event) {
          case PressedButton.play:
            audioService?.resume();
            break;
          case PressedButton.pause:
            audioService?.pause();
            break;
          case PressedButton.next:
            audioService?.next();
            break;
          case PressedButton.previous:
            audioService?.previous();
            break;
          case PressedButton.stop:
            audioService?.stop();
            break;
          default:
            break;
        }
      });
    } catch (e) {
      // smtc initialization failed, fallback silently
    }
  }

  void broadcastState(PlaybackState state) {
    if (!Platform.isWindows || _smtc == null) return;

    try {
      // Update playback status
      if (state.isPlaying) {
        _smtc!.setPlaybackStatus(PlaybackStatus.playing);
      } else if (state.currentSong == null) {
        _smtc!.setPlaybackStatus(PlaybackStatus.stopped);
      } else {
        _smtc!.setPlaybackStatus(PlaybackStatus.paused);
      }

      // Update position and timeline
      _smtc!.updateTimeline(
        PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: state.duration.inMilliseconds,
          positionMs: state.position.inMilliseconds,
        ),
      );

      // Update metadata
      final song = state.currentSong;
      if (song != null) {
        _smtc!.updateMetadata(
          MusicMetadata(
            title: song.title,
            album: song.album,
            artist: song.artist,
            thumbnail: song.artworkPath ?? '',
          ),
        );
      } else {
        _smtc!.clearMetadata();
      }
    } catch (e) {
      // ignore
    }
  }

  void dispose() {
    _buttonSubscription?.cancel();
    _smtc?.dispose();
  }
}
