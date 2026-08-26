import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/services/stub_visualizer_service.dart';
import 'package:sonora/services/visualizer_service.dart';

void main() {
  group('StubVisualizerService', () {
    late VisualizerService service;

    setUp(() {
      service = StubVisualizerService();
    });

    test('1. Should report as unavailable', () {
      expect(service.isAvailable, false);
    });

    test('2. Should return empty stream', () async {
      final events = await service.fftStream.toList();
      expect(events, isEmpty);
    });

    test('3. Methods should not throw', () async {
      // These should be no-ops and not throw exceptions
      await expectLater(service.start(), completes);
      await expectLater(service.stop(), completes);
      expect(() => service.dispose(), returnsNormally);
    });
  });

  // Note: We cannot easily unit-test the AndroidVisualizerService here because
  // it requires a real Flutter engine with Platform Channels and Android APIs.
  // The normalization logic is inside the Kotlin native code for performance.
}
