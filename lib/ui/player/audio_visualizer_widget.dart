import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/visualizer_provider.dart';

/// A performance-optimized widget that displays real-time FFT audio data.
///
/// Uses [RepaintBoundary] and [CustomPainter] to render frequency bars
/// smoothly without rebuilding the surrounding widget tree.
class AudioVisualizerWidget extends ConsumerWidget {
  const AudioVisualizerWidget({
    super.key,
    this.height = 48.0,
    this.width = double.infinity,
    this.barCount = 42,
    this.barSpacing = 2.0,
  });

  final double height;
  final double width;
  final int barCount;
  final double barSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAvailable = ref.watch(visualizerServiceProvider).isAvailable;

    if (!isAvailable) {
      // Visualizer is not available on this platform (e.g., Windows)
      return SizedBox(height: height, width: width);
    }

    final fftData = ref.watch(visualizerFftProvider).valueOrNull ?? [];

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: width,
        child: CustomPaint(
          painter: _VisualizerPainter(
            fftData: fftData,
            color: theme.colorScheme.primary,
            barCount: barCount,
            barSpacing: barSpacing,
          ),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.fftData,
    required this.color,
    required this.barCount,
    required this.barSpacing,
  });

  final List<double> fftData;
  final Color color;
  final int barCount;
  final double barSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (fftData.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Calculate dimensions
    final totalSpacing = (barCount - 1) * barSpacing;
    final barWidth = (size.width - totalSpacing) / barCount;
    if (barWidth <= 0) return;

    // The FFT data typically has more bins than we want to display (e.g. 256).
    // We group them into 'barCount' buckets and average the magnitude.
    final dataSize = fftData.length;
    final bucketSize = dataSize / barCount;

    for (var i = 0; i < barCount; i++) {
      // Calculate average magnitude for this bucket
      final startIndex = (i * bucketSize).floor();
      final endIndex = math.min(((i + 1) * bucketSize).ceil(), dataSize);

      double sum = 0;
      int count = 0;
      for (var j = startIndex; j < endIndex; j++) {
        sum += fftData[j];
        count++;
      }

      final rawMagnitude = count > 0 ? sum / count : 0.0;

      // Apply a non-linear curve (e.g., square root) to make low values more visible
      final magnitude = math.sqrt(rawMagnitude).clamp(0.0, 1.0);

      // We want a minimum height of 2 pixels so the bars are always visible
      final barHeight = math.max(magnitude * size.height, 2.0);

      // Draw from center vertically (or from bottom)
      // We will draw from bottom up here.
      final x = i * (barWidth + barSpacing);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    // Only repaint if the data has actually changed
    if (oldDelegate.color != color ||
        oldDelegate.barCount != barCount ||
        oldDelegate.fftData.length != fftData.length) {
      return true;
    }

    // Check if the data values changed
    for (var i = 0; i < fftData.length; i++) {
      if (oldDelegate.fftData[i] != fftData[i]) return true;
    }

    return false;
  }
}
