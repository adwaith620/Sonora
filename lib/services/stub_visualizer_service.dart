import 'visualizer_service.dart';

/// Stub implementation of [VisualizerService] for platforms
/// that do not support real-time audio visualization.
///
/// Returns [isAvailable] = false and an empty FFT stream.
/// The UI layer should check [isAvailable] and hide the
/// visualizer widget rather than displaying fake data.
class StubVisualizerService implements VisualizerService {
  @override
  bool get isAvailable => false;

  @override
  Stream<List<double>> get fftStream => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
