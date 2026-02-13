import 'package:aurasync/core/models/device_model.dart';

/// Service to coordinate BLE and Audio verification
/// This is the core of the "Dual-Verify" technology
class DualVerifyService {
  // Track devices that have passed dual verification
  final Map<String, DateTime> _dualVerifiedDevices = {};
  
  // How long a dual verification is valid (e.g., 30 seconds)
  static const Duration verificationValidityDuration = Duration(seconds: 30);
  
  // Minimum confidence score for audio verification (0.0 - 1.0)
  static const double audioConfidenceThreshold = 0.7;
  
  /// Check if a device should be considered dual-verified
  /// 
  /// A device is dual-verified when:
  /// 1. It's visible via BLE scan
  /// 2. Audio verification signals are detected (18kHz chirps)
  /// 3. Both signals are "recent" (within verification window)
  bool isDualVerified(DiscoveredDevice device, bool audioDetected) {
    // Must have both BLE and audio signals
    if (!device.isBleVisible || !audioDetected) {
      return false;
    }
    
    // Check if BLE signal is recent (device was seen recently)
    final timeSinceLastSeen = DateTime.now().difference(device.lastSeen);
    if (timeSinceLastSeen > verificationValidityDuration) {
      return false;
    }
    
    // Both conditions met - device is dual-verified!
    return true;
  }
  
  /// Update dual verification status for a device
  /// Records when a device successfully passes dual verification
  void recordDualVerification(String deviceId) {
    _dualVerifiedDevices[deviceId] = DateTime.now();
  }
  
  /// Check if a device was recently dual-verified
  /// Returns true if the device was verified within the validity window
  bool wasRecentlyVerified(String deviceId) {
    final verificationTime = _dualVerifiedDevices[deviceId];
    if (verificationTime == null) {
      return false;
    }
    
    final timeSinceVerification = DateTime.now().difference(verificationTime);
    return timeSinceVerification <= verificationValidityDuration;
  }
  
  /// Remove stale verification records
  /// Called periodically to clean up old verification data
  void cleanupStaleVerifications() {
    final now = DateTime.now();
    _dualVerifiedDevices.removeWhere((key, value) {
      return now.difference(value) > verificationValidityDuration;
    });
  }
  
  /// Calculate a "confidence score" for dual verification
  /// Returns a value between 0.0 (not verified) and 1.0 (highly verified)
  /// 
  /// Factors considered:
  /// - BLE signal strength (stronger = more confident)
  /// - Time since last seen (more recent = more confident)
  /// - Audio detection status
  double getConfidenceScore(DiscoveredDevice device, bool audioDetected) {
    double score = 0.0;
    
    // BLE visibility contributes 40%
    if (device.isBleVisible) {
      // Stronger signal = higher confidence
      // RSSI typically ranges from -100 (weak) to -40 (strong)
      final normalizedRssi = ((device.signalStrength + 100) / 60).clamp(0.0, 1.0);
      score += 0.4 * normalizedRssi;
    }
    
    // Audio detection contributes 40%
    if (audioDetected) {
      score += 0.4;
    }
    
    // Recency contributes 20%
    final timeSinceLastSeen = DateTime.now().difference(device.lastSeen);
    if (timeSinceLastSeen.inSeconds < 5) {
      score += 0.2;
    } else if (timeSinceLastSeen.inSeconds < 15) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Determine if auto-connect should be triggered for this device
  /// Only auto-connect when confidence is high enough
  bool shouldAutoConnect(DiscoveredDevice device, bool audioDetected) {
    // Device must be dual-verified
    if (!isDualVerified(device, audioDetected)) {
      return false;
    }
    
    // Confidence must be above threshold
    final confidence = getConfidenceScore(device, audioDetected);
    if (confidence < audioConfidenceThreshold) {
      return false;
    }
    
    // Don't auto-connect if already connected or connecting
    if (device.connectionState == ConnectionState.connected ||
        device.connectionState == ConnectionState.connecting) {
      return false;
    }
    
    // All conditions met - safe to auto-connect!
    return true;
  }
  
  /// Get a human-readable description of verification status
  String getVerificationStatusDescription(DiscoveredDevice device, bool audioDetected) {
    if (isDualVerified(device, audioDetected)) {
      final confidence = getConfidenceScore(device, audioDetected);
      if (confidence >= 0.9) {
        return 'Dual-Verified (High Confidence)';
      } else if (confidence >= 0.7) {
        return 'Dual-Verified (Medium Confidence)';
      } else {
        return 'Dual-Verified (Low Confidence)';
      }
    } else if (device.isBleVisible && audioDetected) {
      return 'Verifying... (Both signals detected)';
    } else if (device.isBleVisible) {
      return 'BLE Only (Waiting for audio)';
    } else if (audioDetected) {
      return 'Audio Only (Waiting for BLE)';
    } else {
      return 'Not Detected';
    }
  }
  
  /// Clear all verification records
  void clearAll() {
    _dualVerifiedDevices.clear();
  }
}
