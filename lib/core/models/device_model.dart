import 'package:flutter/foundation.dart';

/// Represents different connection states for a device
enum ConnectionState {
  disconnected,
  connecting,
  connected,
}

/// The core device entity.
/// Represents a discovered device in the AuraSync network.
@immutable
class DiscoveredDevice {
  final String id; // BLE ID
  final String name;
  final bool isBleVisible; // True if seen in last 5s
  final bool isAudioVerified; // True if 18kHz heard in last 5s
  final ConnectionState connectionState;
  final DateTime lastSeen;
  final int signalStrength; // RSSI value for visual representation
  final double distanceEstimate; // Rough distance in meters (for radar positioning)
  final double angle; // Angle on radar (0-360 degrees)

  const DiscoveredDevice({
    required this.id,
    required this.name,
    this.isBleVisible = false,
    this.isAudioVerified = false,
    this.connectionState = ConnectionState.disconnected,
    required this.lastSeen,
    this.signalStrength = -100,
    this.distanceEstimate = 0.0,
    this.angle = 0.0,
  });

  /// Returns true if device is dual-verified (both BLE and Audio)
  bool get isDualVerified => isBleVisible && isAudioVerified;

  /// Returns true if device was seen recently (within 5 seconds)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(lastSeen).inSeconds < 5;
  }

  /// Returns the connection status as a human-readable string
  String get statusText {
    if (isDualVerified && connectionState == ConnectionState.connected) {
      return 'Connected & Verified';
    } else if (isDualVerified) {
      return 'Dual-Verified';
    } else if (isBleVisible && isAudioVerified) {
      return 'Verifying...';
    } else if (isBleVisible) {
      return 'BLE Detected';
    } else if (isAudioVerified) {
      return 'Audio Detected';
    } else {
      return 'Searching...';
    }
  }

  /// Creates a copy with modified fields
  DiscoveredDevice copyWith({
    String? id,
    String? name,
    bool? isBleVisible,
    bool? isAudioVerified,
    ConnectionState? connectionState,
    DateTime? lastSeen,
    int? signalStrength,
    double? distanceEstimate,
    double? angle,
  }) {
    return DiscoveredDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      isBleVisible: isBleVisible ?? this.isBleVisible,
      isAudioVerified: isAudioVerified ?? this.isAudioVerified,
      connectionState: connectionState ?? this.connectionState,
      lastSeen: lastSeen ?? this.lastSeen,
      signalStrength: signalStrength ?? this.signalStrength,
      distanceEstimate: distanceEstimate ?? this.distanceEstimate,
      angle: angle ?? this.angle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DiscoveredDevice(id: $id, name: $name, dual-verified: $isDualVerified)';
  }
}
