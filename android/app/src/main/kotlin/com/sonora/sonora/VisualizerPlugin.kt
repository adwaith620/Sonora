package com.sonora.sonora

import android.media.audiofx.Visualizer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin that bridges Android's Visualizer API to Dart via EventChannel.
 *
 * Uses audioSessionId = 0 to capture the global audio output mix,
 * which includes audio from media_kit/libmpv without needing a
 * specific session ID from the player.
 *
 * Requires RECORD_AUDIO and MODIFY_AUDIO_SETTINGS permissions.
 */
class VisualizerPlugin(flutterEngine: FlutterEngine) {

    companion object {
        private const val EVENT_CHANNEL = "com.sonora.sonora/visualizer_fft"
        private const val METHOD_CHANNEL = "com.sonora.sonora/visualizer_control"
        private const val CAPTURE_SIZE = 512 // 256 frequency bins
    }

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null

    init {
        // EventChannel for streaming FFT data to Dart
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        // MethodChannel for start/stop/dispose control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        startVisualizer()
                        result.success(true)
                    }
                    "stop" -> {
                        stopVisualizer()
                        result.success(true)
                    }
                    "isAvailable" -> {
                        result.success(true) // Android always supports Visualizer API
                    }
                    "dispose" -> {
                        disposeVisualizer()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startVisualizer() {
        // Don't create a second visualizer if one is already running
        if (visualizer != null) return

        try {
            // audioSessionId = 0 captures the global audio output mix
            val viz = Visualizer(0)

            // Set capture size (must be a power of 2 within the allowed range)
            val range = Visualizer.getCaptureSizeRange()
            val size = CAPTURE_SIZE.coerceIn(range[0], range[1])
            viz.captureSize = size

            // Use roughly half the max capture rate (~10-15 fps) for efficiency
            val captureRate = Visualizer.getMaxCaptureRate() / 2

            viz.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        visualizer: Visualizer?,
                        waveform: ByteArray?,
                        samplingRate: Int
                    ) {
                        // Not used — we only need FFT data
                    }

                    override fun onFftDataCapture(
                        visualizer: Visualizer?,
                        fft: ByteArray?,
                        samplingRate: Int
                    ) {
                        if (fft == null || eventSink == null) return

                        // Convert FFT byte array to magnitude array.
                        // Android FFT format: [real0, imag0, real1, imag1, ...]
                        // First pair is DC, last pair is Nyquist.
                        // We compute magnitude = sqrt(real^2 + imag^2) for each bin,
                        // then normalize to 0.0..1.0 range.
                        val numBins = fft.size / 2
                        val magnitudes = DoubleArray(numBins)
                        var maxMag = 1.0 // Avoid division by zero

                        for (i in 0 until numBins) {
                            val real = fft[2 * i].toDouble()
                            val imag = fft[2 * i + 1].toDouble()
                            val mag = Math.sqrt(real * real + imag * imag)
                            magnitudes[i] = mag
                            if (mag > maxMag) maxMag = mag
                        }

                        // Normalize to 0.0..1.0
                        for (i in magnitudes.indices) {
                            magnitudes[i] = magnitudes[i] / maxMag
                        }

                        // Send as DoubleArray to Dart (arrives as Float64List)
                        eventSink?.success(magnitudes)
                    }
                },
                captureRate,
                false, // waveform capture disabled
                true   // FFT capture enabled
            )

            viz.enabled = true
            visualizer = viz
        } catch (e: Exception) {
            eventSink?.error("VISUALIZER_ERROR", e.message, null)
        }
    }

    private fun stopVisualizer() {
        visualizer?.enabled = false
    }

    private fun disposeVisualizer() {
        visualizer?.let {
            it.enabled = false
            it.release()
        }
        visualizer = null
        eventSink = null
    }
}
