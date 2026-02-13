import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/core/models/device_model.dart';
import 'package:aurasync/features/audio/providers/audio_detection_provider.dart';
import 'package:aurasync/features/ble/providers/ble_state_provider.dart';
import 'package:aurasync/core/services/dual_verify_service.dart';
import 'package:aurasync/core/services/connection_manager.dart';

/// Provides the list of discovered devices.
/// Now integrates dual-verify logic and auto-connect functionality.
class DeviceStateNotifier extends Notifier<List<DiscoveredDevice>> {
  Timer? _mockTimer;
  Timer? _verificationTimer;
  final Random _random = Random();
  
  // Services for dual-verify and connection management
  final DualVerifyService _dualVerifyService = DualVerifyService();
  final ConnectionManager _connectionManager = ConnectionManager();
  
  // Track which devices have been auto-connected
  final Set<String> _autoConnectedDevices = {};

  @override
  List<DiscoveredDevice> build() {
    // Watch BLE state for discovered devices
    ref.listen(bleStateProvider, (previous, next) {
      _onBleDevicesChanged(next.discoveredDevices);
    });
    
    // Watch audio detection state
    ref.listen(audioDetectionProvider, (previous, next) {
      _onAudioDetectionChanged(next.isDetected);
    });
    
    // Listen to connection events
    _connectionManager.connectionEvents.listen(_onConnectionEvent);
    
    // Start verification timer
    _startVerificationTimer();
    
    // Initialize with empty list (no mock data in production)
    // Uncomment for testing: _startMockDataGeneration();
    
    // Register cleanup
    ref.onDispose(() {
      _mockTimer?.cancel();
      _verificationTimer?.cancel();
      _connectionManager.dispose();
    });
    
    return [];
  }

  /// Handle BLE devices discovered
  void _onBleDevicesChanged(List bleDevices) {
    // Import BLE devices and merge with existing state
    final now = DateTime.now();
    
    // Create a map of existing devices
    final existingDevices = {for (var d in state) d.id: d};
    
    // Update or add BLE devices
    for (final bleDevice in bleDevices) {
      final existing = existingDevices[bleDevice.id];
      
      if (existing != null) {
        // Update existing device
        final updated = existing.copyWith(
          name: bleDevice.name,
          isBleVisible: true,
          signalStrength: bleDevice.rssi,
          distanceEstimate: bleDevice.estimatedDistance,
          lastSeen: now,
          // Keep audio verification status
          // (could be enhanced to match specific BLE device with audio source)
        );
        existingDevices[bleDevice.id] = updated;
      } else {
        // Add new BLE device
        final newDevice = DiscoveredDevice(
          id: bleDevice.id,
          name: bleDevice.name,
          isBleVisible: true,
          isAudioVerified: false, // Not audio verified yet
          lastSeen: now,
          signalStrength: bleDevice.rssi,
          distanceEstimate: bleDevice.estimatedDistance,
          angle: _random.nextDouble() * 360, // Random angle for now
          connectionState: ConnectionState.disconnected,
        );
        existingDevices[bleDevice.id] = newDevice;
      }
    }
    
    // Mark devices not in BLE scan as not BLE visible
    final bleDeviceIds = bleDevices.map((d) => d.id).toSet();
    for (final entry in existingDevices.entries) {
      if (!bleDeviceIds.contains(entry.key)) {
        existingDevices[entry.key] = entry.value.copyWith(
          isBleVisible: false,
        );
      }
    }
    
    state = existingDevices.values.toList();
    
    // Check for auto-connect opportunities
    _checkAutoConnect();
  }
  
  /// Handle audio detection state changes
  void _onAudioDetectionChanged(bool isDetected) {
    // Update audio verification for all visible BLE devices
    final now = DateTime.now();
    final updatedDevices = state.map((device) {
      // Only update devices that are currently BLE visible
      if (device.isBleVisible) {
        return device.copyWith(
          isAudioVerified: isDetected,
          lastSeen: now,
        );
      }
      return device;
    }).toList();
    
    state = updatedDevices;
    
    // Check for auto-connect opportunities
    _checkAutoConnect();
  }
  
  /// Check if any devices should be auto-connected
  void _checkAutoConnect() {
    final audioDetected = ref.read(audioDetectionProvider).isDetected;
    
    for (final device in state) {
      // Skip if already auto-connected
      if (_autoConnectedDevices.contains(device.id)) {
        continue;
      }
      
      // Check if should auto-connect
      if (_dualVerifyService.shouldAutoConnect(device, audioDetected)) {
        // Record verification
        _dualVerifyService.recordDualVerification(device.id);
        
        // Trigger auto-connect
        _autoConnectedDevices.add(device.id);
        _connectionManager.autoConnect(device);
      }
    }
  }
  
  /// Handle connection events from ConnectionManager
  void _onConnectionEvent(ConnectionEvent event) {
    // Update device connection state
    final updatedDevices = state.map((device) {
      if (device.id == event.deviceId) {
        return device.copyWith(connectionState: event.state);
      }
      return device;
    }).toList();
    
    state = updatedDevices;
  }
  
  /// Start verification timer to cleanup stale records
  void _startVerificationTimer() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _dualVerifyService.cleanupStaleVerifications();
    });
  }

  /// Start generating mock devices that move around the radar
  /// DEPRECATED: Mock data generation disabled in Phase 5
  /// Uncomment _startMockDataGeneration() in build() method to re-enable
  // ignore: unused_element
  void _startMockDataGeneration() {
    // Clean up any existing timer
    _mockTimer?.cancel();

    // Generate initial mock devices
    state = _generateMockDevices();

    // Update mock devices every 2 seconds to simulate movement
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      state = _updateMockDevices(state);
    });

    // Register cleanup
    ref.onDispose(() {
      _mockTimer?.cancel();
    });
  }

  /// Generate initial mock devices
  List<DiscoveredDevice> _generateMockDevices() {
    final now = DateTime.now();
    return [
      DiscoveredDevice(
        id: 'mock-device-1',
        name: 'Alice\'s Phone',
        isBleVisible: true,
        isAudioVerified: false,
        lastSeen: now,
        signalStrength: -65,
        distanceEstimate: 2.5,
        angle: 45.0,
        connectionState: ConnectionState.disconnected,
      ),
      DiscoveredDevice(
        id: 'mock-device-2',
        name: 'Bob\'s Laptop',
        isBleVisible: true,
        isAudioVerified: true, // This one is dual-verified
        lastSeen: now,
        signalStrength: -45,
        distanceEstimate: 1.2,
        angle: 120.0,
        connectionState: ConnectionState.connected,
      ),
      DiscoveredDevice(
        id: 'mock-device-3',
        name: 'Charlie\'s Tablet',
        isBleVisible: false,
        isAudioVerified: true,
        lastSeen: now.subtract(const Duration(seconds: 3)),
        signalStrength: -80,
        distanceEstimate: 4.5,
        angle: 270.0,
        connectionState: ConnectionState.disconnected,
      ),
    ];
  }

  /// Update mock devices to simulate movement and changing states
  List<DiscoveredDevice> _updateMockDevices(List<DiscoveredDevice> devices) {
    // Get current audio detection state
    final audioDetected = ref.read(audioDetectionProvider).isDetected;
    
    return devices.map((device) {
      // Randomly update angle (simulate device moving)
      final newAngle = (device.angle + _random.nextDouble() * 30 - 15) % 360;
      
      // Slightly vary distance
      final newDistance = (device.distanceEstimate + (_random.nextDouble() - 0.5) * 0.5)
          .clamp(0.5, 5.0);
      
      // For mock device 2 (Bob's Laptop), tie audio verification to actual detection
      bool newAudioVerified;
      if (device.id == 'mock-device-2') {
        // This device reflects real audio detection
        newAudioVerified = audioDetected;
      } else {
        // Other devices occasionally toggle (for demonstration)
        newAudioVerified = _random.nextDouble() > 0.3 
            ? device.isAudioVerified 
            : !device.isAudioVerified;
      }
      
      // Update BLE visibility
      final newBleVisible = _random.nextDouble() > 0.2 
          ? device.isBleVisible 
          : !device.isBleVisible;

      return device.copyWith(
        angle: newAngle,
        distanceEstimate: newDistance,
        isAudioVerified: newAudioVerified,
        isBleVisible: newBleVisible,
        lastSeen: DateTime.now(),
        signalStrength: -40 - (_random.nextInt(50)),
      );
    }).toList();
  }

  /// Manually add a device (for future use)
  void addDevice(DiscoveredDevice device) {
    if (!state.any((d) => d.id == device.id)) {
      state = [...state, device];
    }
  }

  /// Update an existing device
  void updateDevice(DiscoveredDevice device) {
    state = [
      for (final d in state)
        if (d.id == device.id) device else d,
    ];
  }
  
  /// Manually connect to a device
  Future<void> connectToDevice(DiscoveredDevice device) async {
    await _connectionManager.connectToDevice(device.id, device.name);
  }
  
  /// Manually disconnect from a device
  Future<void> disconnectFromDevice(DiscoveredDevice device) async {
    await _connectionManager.disconnectFromDevice(device.id, device.name);
    _autoConnectedDevices.remove(device.id);
  }
  
  /// Get verification status for a device
  String getVerificationStatus(DiscoveredDevice device) {
    final audioDetected = ref.read(audioDetectionProvider).isDetected;
    return _dualVerifyService.getVerificationStatusDescription(device, audioDetected);
  }
  
  /// Get confidence score for a device
  double getConfidenceScore(DiscoveredDevice device) {
    final audioDetected = ref.read(audioDetectionProvider).isDetected;
    return _dualVerifyService.getConfidenceScore(device, audioDetected);
  }

  /// Remove a device
  void removeDevice(String deviceId) {
    state = state.where((d) => d.id != deviceId).toList();
  }

  /// Clear all devices
  void clearDevices() {
    state = [];
  }
}

/// The global provider for device state
final deviceStateProvider = NotifierProvider<DeviceStateNotifier, List<DiscoveredDevice>>(
  DeviceStateNotifier.new,
);
