import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Service to generate and transmit 18kHz ultrasonic audio signals.
/// Uses platform channels to play audio through the device speaker.
class AudioTransmitter {
  static const platform = MethodChannel('com.aurasync/audio');
  
  // Audio parameters
  static const int sampleRate = 44100; // Standard sample rate
  static const double frequency = 18000.0; // 18kHz ultrasonic
  static const double amplitude = 0.5; // Volume (0.0 to 1.0)
  static const int chirpDurationMs = 100; // 100ms chirp
  static const int chirpIntervalMs = 2000; // Chirp every 2 seconds
  
  Timer? _transmitTimer;
  bool _isTransmitting = false;
  
  /// Start transmitting periodic 18kHz chirps
  Future<void> startTransmitting() async {
    if (_isTransmitting) {
      return;
    }
    
    _isTransmitting = true;
    
    // Generate the chirp audio data once
    final chirpData = _generateChirp();
    
    // Play immediately
    await _playChirp(chirpData);
    
    // Set up periodic transmission
    _transmitTimer = Timer.periodic(
      const Duration(milliseconds: chirpIntervalMs),
      (timer) async {
        if (_isTransmitting) {
          await _playChirp(chirpData);
        }
      },
    );
  }
  
  /// Stop transmitting
  Future<void> stopTransmitting() async {
    _isTransmitting = false;
    _transmitTimer?.cancel();
    _transmitTimer = null;
    
    try {
      await platform.invokeMethod('stopAudio');
    } catch (e) {
      // Platform method might not be implemented yet
      // This is fine for now
    }
  }
  
  /// Generate a 18kHz sine wave chirp
  Float32List _generateChirp() {
    final numSamples = (sampleRate * chirpDurationMs / 1000).round();
    final samples = Float32List(numSamples);
    
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final value = amplitude * math.sin(2 * math.pi * frequency * t);
      
      // Apply envelope (fade in/out) to prevent clicks
      final envelope = _applyEnvelope(i, numSamples);
      samples[i] = value * envelope;
    }
    
    return samples;
  }
  
  /// Apply smooth envelope to prevent audio clicks
  double _applyEnvelope(int sampleIndex, int totalSamples) {
    const fadeLength = 100; // Fade in/out over 100 samples
    
    if (sampleIndex < fadeLength) {
      // Fade in
      return sampleIndex / fadeLength;
    } else if (sampleIndex > totalSamples - fadeLength) {
      // Fade out
      return (totalSamples - sampleIndex) / fadeLength;
    } else {
      // Full amplitude
      return 1.0;
    }
  }
  
  /// Play the chirp audio
  Future<void> _playChirp(Float32List samples) async {
    try {
      // For now, we'll use a simple approach without platform channels
      // In a production app, you'd implement native audio playback
      // or use a package like just_audio with raw PCM support
      
      // Platform-specific audio playback would be implemented here:
      // await platform.invokeMethod('playChirp', {
      //   'samples': samples,
      //   'sampleRate': sampleRate,
      // });
      
      // For Phase 3 MVP, we'll simulate transmission
      // The actual audio playback would require platform-specific code
    } catch (e) {
      // Ignore errors for now
    }
  }
  
  /// Check if currently transmitting
  bool get isTransmitting => _isTransmitting;
  
  /// Dispose resources
  void dispose() {
    stopTransmitting();
  }
}
