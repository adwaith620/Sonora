/// Abstract interface for audio visualization data.
///
/// Platform implementations provide real FFT data from the
/// system's audio output. Non-supported platforms return
/// [isAvailable] = false and an empty stream.
library;

/// Service that provides real-time FFT audio data for visualization.
abstract class VisualizerService {
  /// Whether the visualizer is available on this platform.
  bool get isAvailable;

  /// Stream of normalized FFT magnitude data.
  ///
  /// Each emission is a list of doubles in the range 0.0..1.0,
  /// representing frequency bin magnitudes from low to high.
  /// The list length depends on the FFT capture size (typically 256 bins).
  ///
  /// The stream emits only when the visualizer is started.
  Stream<List<double>> get fftStream;

  /// Start capturing FFT data.
  Future<void> start();

  /// Stop capturing FFT data (can be resumed with [start]).
  Future<void> stop();

  /// Release all native resources. Cannot be used after this.
  void dispose();
}
