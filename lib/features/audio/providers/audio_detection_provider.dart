import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/features/audio/services/audio_receiver.dart';
import 'package:aurasync/features/audio/services/audio_transmitter.dart';

/// Represents the state of audio detection
class AudioDetectionState {
  final bool isDetected;
  final bool isListening;
  final bool isTransmitting;
  final DateTime? lastDetectionTime;
  final double? lastPeakFrequency;
  final double? lastPeakMagnitude;
  final String? errorMessage;
  
  const AudioDetectionState({
    this.isDetected = false,
    this.isListening = false,
    this.isTransmitting = false,
    this.lastDetectionTime,
    this.lastPeakFrequency,
    this.lastPeakMagnitude,
    this.errorMessage,
  });
  
  /// Check if detection is recent (within 5 seconds)
  bool get isRecentlyDetected {
    if (lastDetectionTime == null) return false;
    final now = DateTime.now();
    return now.difference(lastDetectionTime!).inSeconds < 5;
  }
  
  AudioDetectionState copyWith({
    bool? isDetected,
    bool? isListening,
    bool? isTransmitting,
    DateTime? lastDetectionTime,
    double? lastPeakFrequency,
    double? lastPeakMagnitude,
    String? errorMessage,
  }) {
    return AudioDetectionState(
      isDetected: isDetected ?? this.isDetected,
      isListening: isListening ?? this.isListening,
      isTransmitting: isTransmitting ?? this.isTransmitting,
      lastDetectionTime: lastDetectionTime ?? this.lastDetectionTime,
      lastPeakFrequency: lastPeakFrequency ?? this.lastPeakFrequency,
      lastPeakMagnitude: lastPeakMagnitude ?? this.lastPeakMagnitude,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for managing audio detection state
class AudioDetectionNotifier extends Notifier<AudioDetectionState> {
  AudioReceiver? _receiver;
  AudioTransmitter? _transmitter;
  StreamSubscription<AudioAnalysisResult>? _detectionSubscription;
  Timer? _detectionTimeoutTimer;
  
  @override
  AudioDetectionState build() {
    // Initialize services
    _receiver = AudioReceiver();
    _transmitter = AudioTransmitter();
    
    // Cleanup on dispose
    ref.onDispose(() {
      _cleanup();
    });
    
    return const AudioDetectionState();
  }
  
  /// Start audio system (both transmitter and receiver)
  Future<void> start() async {
    try {
      // Start transmitter
      await _startTransmitter();
      
      // Start receiver
      await _startReceiver();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start audio: $e',
        isListening: false,
        isTransmitting: false,
      );
    }
  }
  
  /// Stop audio system
  Future<void> stop() async {
    await _stopTransmitter();
    await _stopReceiver();
    _detectionTimeoutTimer?.cancel();
  }
  
  /// Start only the transmitter
  Future<void> _startTransmitter() async {
    try {
      await _transmitter?.startTransmitting();
      state = state.copyWith(isTransmitting: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start transmitter: $e',
        isTransmitting: false,
      );
    }
  }
  
  /// Stop the transmitter
  Future<void> _stopTransmitter() async {
    await _transmitter?.stopTransmitting();
    state = state.copyWith(isTransmitting: false);
  }
  
  /// Start only the receiver
  Future<void> _startReceiver() async {
    try {
      await _receiver?.startListening();
      
      // Subscribe to detection results
      _detectionSubscription = _receiver?.detectionStream.listen(
        _onDetectionResult,
        onError: (error) {
          state = state.copyWith(
            errorMessage: 'Audio detection error: $error',
            isListening: false,
          );
        },
      );
      
      state = state.copyWith(isListening: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start receiver: $e',
        isListening: false,
      );
    }
  }
  
  /// Stop the receiver
  Future<void> _stopReceiver() async {
    await _detectionSubscription?.cancel();
    _detectionSubscription = null;
    await _receiver?.stopListening();
    state = state.copyWith(isListening: false);
  }
  
  /// Handle detection result from receiver
  void _onDetectionResult(AudioAnalysisResult result) {
    if (result.detected) {
      // Cancel existing timeout timer
      _detectionTimeoutTimer?.cancel();
      
      // Update state with detection
      state = state.copyWith(
        isDetected: true,
        lastDetectionTime: result.timestamp,
        lastPeakFrequency: result.peakFrequency,
        lastPeakMagnitude: result.peakMagnitude,
        errorMessage: null,
      );
      
      // Set timeout to clear detection after 5 seconds
      _detectionTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!state.isRecentlyDetected) {
          state = state.copyWith(isDetected: false);
        }
      });
    }
  }
  
  /// Toggle transmitter on/off
  Future<void> toggleTransmitter() async {
    if (state.isTransmitting) {
      await _stopTransmitter();
    } else {
      await _startTransmitter();
    }
  }
  
  /// Toggle receiver on/off
  Future<void> toggleReceiver() async {
    if (state.isListening) {
      await _stopReceiver();
    } else {
      await _startReceiver();
    }
  }
  
  /// Cleanup resources
  void _cleanup() {
    _detectionTimeoutTimer?.cancel();
    _detectionSubscription?.cancel();
    _receiver?.dispose();
    _transmitter?.dispose();
  }
}

/// Provider for audio detection state
final audioDetectionProvider = NotifierProvider<AudioDetectionNotifier, AudioDetectionState>(
  AudioDetectionNotifier.new,
);
