import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'visualizer_service.dart';

/// Android implementation of [VisualizerService].
///
/// Uses the Android `Visualizer` API with `audioSessionId = 0` to capture
/// the global audio output mix. This captures audio from media_kit/libmpv
/// without needing the player's specific audio session ID.
///
/// Requires `RECORD_AUDIO` and `MODIFY_AUDIO_SETTINGS` permissions.
class AndroidVisualizerService implements VisualizerService {
  AndroidVisualizerService();

  static const _eventChannel = EventChannel('com.sonora.sonora/visualizer_fft');
  static const _methodChannel = MethodChannel(
    'com.sonora.sonora/visualizer_control',
  );

  StreamSubscription<dynamic>? _subscription;
  final _controller = StreamController<List<double>>.broadcast();

  @override
  bool get isAvailable => true;

  @override
  Stream<List<double>> get fftStream => _controller.stream;

  @override
  Future<void> start() async {
    try {
      await _methodChannel.invokeMethod<bool>('start');

      // Only subscribe if we aren't already
      _subscription ??= _eventChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          if (data is Float64List) {
            // EventChannel sends DoubleArray as Float64List
            _controller.add(data.toList(growable: false));
          } else if (data is List) {
            // Fallback just in case
            final magnitudes = data.cast<double>();
            _controller.add(magnitudes.toList(growable: false));
          }
        },
        onError: (dynamic error) {
          // Silently handle errors — visualizer is non-critical
        },
      );
    } on PlatformException {
      // Permission denied or other platform error — silently degrade
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<bool>('stop');
    } on PlatformException {
      // Silently handle
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _methodChannel.invokeMethod<bool>('dispose');
    } on PlatformException {
      // Silently handle
    }
    _controller.close();
  }
}
