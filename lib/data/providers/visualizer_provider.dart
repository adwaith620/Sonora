import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_utils.dart';
import '../../services/android_visualizer_service.dart';
import '../../services/stub_visualizer_service.dart';
import '../../services/visualizer_service.dart';
import 'audio_provider.dart';

/// Provides the platform-appropriate [VisualizerService].
///
/// On Android: uses the real Android Visualizer API (FFT from global audio).
/// On other platforms: uses a stub that reports isAvailable = false.
final visualizerServiceProvider = Provider<VisualizerService>((ref) {
  final VisualizerService service;

  if (isAndroid) {
    service = AndroidVisualizerService();
  } else {
    service = StubVisualizerService();
  }

  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides a stream of FFT magnitude data, gated by playback state.
///
/// Automatically starts the visualizer when playing and stops when
/// paused/stopped. Returns null when the visualizer is not available.
final visualizerFftProvider = StreamProvider.autoDispose<List<double>?>((ref) {
  final service = ref.watch(visualizerServiceProvider);
  if (!service.isAvailable) {
    return const Stream.empty();
  }

  final playbackState = ref.watch(playbackStateProvider);

  if (playbackState.isPlaying) {
    service.start();
  } else {
    service.stop();
  }

  ref.onDispose(() => service.stop());

  return service.fftStream;
});
