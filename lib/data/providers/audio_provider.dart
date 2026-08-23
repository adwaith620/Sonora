import 'package:audio_service/audio_service.dart' hide PlaybackState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio_player_service.dart';
import '../../services/media_kit_audio_service.dart';
import '../../services/audio_handler.dart';
import 'queue_provider.dart';

/// Provider for the current playback state and queue logic.
final playbackStateNotifierProvider = NotifierProvider<PlaybackStateNotifier, PlaybackState>(() {
  return PlaybackStateNotifier();
});

/// Alias for watching just the state
final playbackStateProvider = Provider<PlaybackState>((ref) {
  return ref.watch(playbackStateNotifierProvider);
});

final audioHandlerProvider = Provider<SonoraAudioHandler?>((ref) {
  return null; // Will be overridden in main() after initialization
});

/// Provider for the audio player service.
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final notifier = ref.read(playbackStateNotifierProvider.notifier);
  final handler = ref.read(audioHandlerProvider);
  
  final service = MediaKitAudioService(notifier, handler);
  
  service.init();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
