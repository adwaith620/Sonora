import 'dart:async';

import 'package:media_kit/media_kit.dart';

import '../data/models/song.dart';
import '../data/providers/queue_provider.dart';
import 'audio_player_service.dart';
import 'audio_handler.dart';
import 'windows_smtc_handler.dart';

class MediaKitAudioService implements AudioPlayerService {
  MediaKitAudioService(this._notifier, this._handler, this._smtcHandler) {
    _player = Player();
    _handler?.audioService = this;
    _smtcHandler?.audioService = this;

    _player.stream.playing.listen((isPlaying) {
      final newState = _notifier.currentState.copyWith(isPlaying: isPlaying);
      _notifier.updateState(newState);
      _handler?.broadcastState(newState);
      _smtcHandler?.broadcastState(newState);
    });

    _player.stream.position.listen((position) {
      final newState = _notifier.currentState.copyWith(position: position);
      _notifier.updateState(newState);
      _handler?.broadcastState(newState);
      _smtcHandler?.broadcastState(newState);
    });

    _player.stream.duration.listen((duration) {
      final newState = _notifier.currentState.copyWith(duration: duration);
      _notifier.updateState(newState);
      _handler?.broadcastState(newState);
      _smtcHandler?.broadcastState(newState);
    });

    _player.stream.buffer.listen((buffer) {
      final newState = _notifier.currentState.copyWith(
        bufferedPosition: buffer,
      );
      _notifier.updateState(newState);
      _handler?.broadcastState(newState);
      _smtcHandler?.broadcastState(newState);
    });

    _player.stream.volume.listen((volume) {
      final newState = _notifier.currentState.copyWith(volume: volume / 100.0);
      _notifier.updateState(newState);
    });

    _player.stream.error.listen((error) {
      final newState = _notifier.currentState.copyWith(error: error);
      _notifier.updateState(newState);
      _handler?.broadcastState(newState);
      _smtcHandler?.broadcastState(newState);
    });

    _player.stream.playlist.listen((playlist) {
      if (playlist.index >= 0 && playlist.index < currentState.queue.length) {
        final currentSong = currentState.queue[playlist.index];
        final newState = _notifier.currentState.copyWith(
          currentIndex: playlist.index,
          currentSong: currentSong,
        );
        _notifier.updateState(newState);
        _handler?.broadcastState(newState);
        _smtcHandler?.broadcastState(newState);
      }
    });
  }

  final PlaybackStateNotifier _notifier;
  final SonoraAudioHandler? _handler;
  final SonoraWindowsSMTCHandler? _smtcHandler;
  late final Player _player;

  @override
  Stream<PlaybackState> get playbackStateStream => const Stream.empty(); // Not used anymore

  @override
  PlaybackState get currentState => _notifier.currentState;

  @override
  Future<void> init() async {}

  @override
  Future<void> playSong(Song song, {List<Song>? queue}) async {
    final q = queue ?? [song];
    await playQueue(q, startIndex: q.indexOf(song).clamp(0, q.length - 1));
  }

  @override
  Future<void> playQueue(List<Song> queue, {int startIndex = 0}) async {
    _notifier.playQueue(queue, startIndex: startIndex);
    await _syncPlaylistToPlayer();
  }

  Future<void> _syncPlaylistToPlayer() async {
    final medias = currentState.queue
        .map((song) => Media(song.fileUri))
        .toList();
    final playlist = Playlist(medias, index: currentState.currentIndex);

    await _applyRepeatModeToPlayer(currentState.repeatMode);
    await _player.open(playlist, play: true);
  }

  Future<void> _applyRepeatModeToPlayer(SonoraRepeatMode mode) async {
    PlaylistMode mediaKitMode;
    switch (mode) {
      case SonoraRepeatMode.off:
        mediaKitMode = PlaylistMode.none;
        break;
      case SonoraRepeatMode.all:
        mediaKitMode = PlaylistMode.loop;
        break;
      case SonoraRepeatMode.one:
        mediaKitMode = PlaylistMode.single;
        break;
    }
    await _player.setPlaylistMode(mediaKitMode);
  }

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> resume() async => await _player.play();

  @override
  Future<void> togglePlayPause() async => await _player.playOrPause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _notifier.updateState(
      _notifier.currentState.copyWith(
        isPlaying: false,
        position: Duration.zero,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  Future<void> next() async => await _player.next();

  @override
  Future<void> previous() async {
    if (currentState.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
    } else {
      await _player.previous();
    }
  }

  @override
  Future<void> setVolume(double volume) async =>
      await _player.setVolume(volume * 100.0);

  @override
  Future<void> toggleShuffle() async {
    _notifier.toggleShuffle();
    await _player.open(
      Playlist(
        currentState.queue.map((s) => Media(s.fileUri)).toList(),
        index: currentState.currentIndex,
      ),
      play: currentState.isPlaying,
    );
  }

  @override
  Future<void> cycleRepeatMode() async {
    _notifier.cycleRepeatMode();
    await _applyRepeatModeToPlayer(currentState.repeatMode);
  }

  @override
  Future<void> addToQueue(Song song) async {
    _notifier.addToQueue(song);
    await _player.add(Media(song.fileUri));
  }

  @override
  Future<void> addToQueueNext(Song song) async {
    _notifier.addToQueueNext(song);
    await _player.open(
      Playlist(
        currentState.queue.map((s) => Media(s.fileUri)).toList(),
        index: currentState.currentIndex,
      ),
      play: currentState.isPlaying,
    );
  }

  @override
  Future<void> removeFromQueue(int index) async {
    _notifier.removeFromQueue(index);
    await _player.remove(index);
  }

  @override
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    _notifier.reorderQueue(oldIndex, newIndex);
    await _player.move(oldIndex, newIndex);
  }

  @override
  Future<void> clearQueue() async {
    _notifier.clearQueue();
    final current = currentState.currentSong;
    if (current == null) {
      await _player.open(const Playlist([]));
    } else {
      await _player.open(
        Playlist([Media(current.fileUri)]),
        play: currentState.isPlaying,
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
