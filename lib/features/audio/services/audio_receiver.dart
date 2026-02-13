import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:mic_stream/mic_stream.dart';
import 'package:fftea/fftea.dart' as fftea;
import 'package:fftea/fftea.dart' show FFT;

/// Configuration for the audio receiver
class AudioReceiverConfig {
  final int sampleRate;
  final int fftSize;
  final double targetFrequency;
  final double frequencyTolerance;
  final double detectionThreshold;
  
  const AudioReceiverConfig({
    this.sampleRate = 44100,
    this.fftSize = 4096,
    this.targetFrequency = 18000.0,
    this.frequencyTolerance = 500.0, // ±500Hz (17.5kHz - 18.5kHz)
    this.detectionThreshold = 0.1, // Minimum magnitude to consider as detection
  });
}

/// Result from audio analysis
class AudioAnalysisResult {
  final bool detected;
  final double peakFrequency;
  final double peakMagnitude;
  final DateTime timestamp;
  
  const AudioAnalysisResult({
    required this.detected,
    required this.peakFrequency,
    required this.peakMagnitude,
    required this.timestamp,
  });
}

/// Service to receive and analyze audio for 18kHz detection.
/// Runs FFT analysis in a separate Isolate to prevent UI lag.
class AudioReceiver {
  final AudioReceiverConfig config;
  
  StreamSubscription<Uint8List>? _micSubscription;
  Stream<Uint8List>? _micStream;
  
  Isolate? _analysisIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  
  final _detectionController = StreamController<AudioAnalysisResult>.broadcast();
  
  bool _isListening = false;
  
  AudioReceiver({this.config = const AudioReceiverConfig()});
  
  /// Stream of audio detection results
  Stream<AudioAnalysisResult> get detectionStream => _detectionController.stream;
  
  /// Start listening to microphone and analyzing audio
  Future<void> startListening() async {
    if (_isListening) {
      return;
    }
    
    try {
      // Start the FFT analysis isolate
      await _startAnalysisIsolate();
      
      // Start microphone stream
      _micStream = MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: config.sampleRate,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );
      
      // Listen to mic data and send to isolate for analysis
      _micSubscription = _micStream!.listen(
        _onMicData,
        onError: (error) {
          _detectionController.addError(error);
        },
      );
      
      _isListening = true;
    } catch (e) {
      _isListening = false;
      rethrow;
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    
    await _micSubscription?.cancel();
    _micSubscription = null;
    
    _stopAnalysisIsolate();
  }
  
  /// Start the isolate for FFT analysis
  Future<void> _startAnalysisIsolate() async {
    _receivePort = ReceivePort();
    
    _analysisIsolate = await Isolate.spawn(
      _audioAnalysisIsolate,
      _AnalysisIsolateParams(
        sendPort: _receivePort!.sendPort,
        config: config,
      ),
    );
    
    // Wait for the SendPort from the isolate
    final completer = Completer<SendPort>();
    _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is AudioAnalysisResult) {
        _detectionController.add(message);
      }
    });
    
    _sendPort = await completer.future;
  }
  
  /// Stop the analysis isolate
  void _stopAnalysisIsolate() {
    _analysisIsolate?.kill(priority: Isolate.immediate);
    _analysisIsolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
  }
  
  /// Handle incoming microphone data
  void _onMicData(Uint8List data) {
    if (_sendPort != null && _isListening) {
      // Send raw audio data to isolate for analysis
      _sendPort!.send(data);
    }
  }
  
  /// Check if currently listening
  bool get isListening => _isListening;
  
  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _detectionController.close();
  }
}

/// Parameters for the analysis isolate
class _AnalysisIsolateParams {
  final SendPort sendPort;
  final AudioReceiverConfig config;
  
  _AnalysisIsolateParams({
    required this.sendPort,
    required this.config,
  });
}

/// Isolate entry point for audio analysis
void _audioAnalysisIsolate(_AnalysisIsolateParams params) {
  final receivePort = ReceivePort();
  
  // Send our SendPort back to the main isolate
  params.sendPort.send(receivePort.sendPort);
  
  // Create FFT instance
  final fft = FFT(params.config.fftSize);
  final window = fftea.Window.hanning(params.config.fftSize);
  
  // Buffer to accumulate samples
  final buffer = <double>[];
  
  receivePort.listen((message) {
    if (message is Uint8List) {
      // Convert bytes to samples (16-bit PCM)
      final samples = _convertBytesToSamples(message);
      buffer.addAll(samples);
      
      // Process when we have enough samples
      while (buffer.length >= params.config.fftSize) {
        final chunk = buffer.sublist(0, params.config.fftSize);
        buffer.removeRange(0, params.config.fftSize);
        
        final result = _analyzeChunk(
          chunk,
          fft,
          window,
          params.config,
        );
        
        // Send result back to main isolate
        params.sendPort.send(result);
      }
    }
  });
}

/// Convert 16-bit PCM bytes to normalized samples
List<double> _convertBytesToSamples(Uint8List bytes) {
  final samples = <double>[];
  
  for (int i = 0; i < bytes.length - 1; i += 2) {
    // Convert two bytes to 16-bit signed integer
    final int sample = (bytes[i + 1] << 8) | bytes[i];
    final int signedSample = sample > 32767 ? sample - 65536 : sample;
    
    // Normalize to -1.0 to 1.0
    samples.add(signedSample / 32768.0);
  }
  
  return samples;
}

/// Analyze a chunk of audio using FFT
AudioAnalysisResult _analyzeChunk(
  List<double> samples,
  FFT fft,
  dynamic window,
  AudioReceiverConfig config,
) {
  // Apply window function
  final windowed = window.apply(samples);
  
  // Perform FFT
  final freq = fft.realFft(windowed);
  
  // Calculate magnitude spectrum
  final magnitudes = <double>[];
  for (var complex in freq) {
    final magnitude = complex.abs() as double;
    magnitudes.add(magnitude);
  }
  
  // Find peak frequency in target range
  final binWidth = config.sampleRate / config.fftSize;
  final minBin = ((config.targetFrequency - config.frequencyTolerance) / binWidth).round();
  final maxBin = ((config.targetFrequency + config.frequencyTolerance) / binWidth).round();
  
  double peakMagnitude = 0.0;
  int peakBin = 0;
  
  for (int i = minBin; i < maxBin && i < magnitudes.length; i++) {
    if (magnitudes[i] > peakMagnitude) {
      peakMagnitude = magnitudes[i];
      peakBin = i;
    }
  }
  
  final peakFrequency = peakBin * binWidth;
  final detected = peakMagnitude > config.detectionThreshold;
  
  return AudioAnalysisResult(
    detected: detected,
    peakFrequency: peakFrequency,
    peakMagnitude: peakMagnitude,
    timestamp: DateTime.now(),
  );
}
