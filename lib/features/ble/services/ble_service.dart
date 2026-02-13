import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:aurasync/core/constants/ble_constants.dart';

/// Represents a discovered BLE device
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final DateTime lastSeen;
  
  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.lastSeen,
  });
  
  /// Estimate distance in meters based on RSSI
  /// Note: This is a rough approximation
  double get estimatedDistance {
    // Simple distance estimation using path loss model
    // d = 10 ^ ((RSSI_measured - RSSI_at_1m) / (10 * n))
    // where n = path loss exponent (typically 2-4)
    const rssiAt1m = -50;
    const pathLossExponent = 2.5;
    
    final distance = pow(10, (rssiAt1m - rssi) / (10 * pathLossExponent));
    return distance.toDouble().clamp(0.1, 10.0);
  }
  
  BleDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    DateTime? lastSeen,
  }) {
    return BleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

/// Service to handle BLE scanning and advertising
class BleService {
  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _discoveredDevices = <String, BleDevice>{};
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _cleanupTimer;
  
  bool _isScanning = false;
  bool _isAdvertising = false;
  
  /// Stream of discovered BLE devices
  Stream<List<BleDevice>> get deviceStream => _scanResultsController.stream;
  
  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }
  
  /// Start scanning for AuraSync devices
  Future<void> startScanning() async {
    if (_isScanning) {
      return;
    }
    
    try {
      // Check if Bluetooth is available
      final isAvailable = await isBluetoothAvailable();
      if (!isAvailable) {
        throw Exception('Bluetooth is not available or turned off');
      }
      
      _isScanning = true;
      
      // Start scanning with service UUID filter
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuid)],
        timeout: const Duration(seconds: 15),
      );
      
      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _onScanResults,
        onError: (error) {
          _isScanning = false;
        },
      );
      
      // Start cleanup timer to remove stale devices
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _cleanupStaleDevices();
      });
    } catch (e) {
      _isScanning = false;
      rethrow;
    }
  }
  
  /// Stop scanning
  Future<void> stopScanning() async {
    _isScanning = false;
    
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // Ignore errors when stopping scan
    }
  }
  
  /// Start advertising as an AuraSync device
  Future<void> startAdvertising() async {
    // Note: Advertising is platform-specific and not fully supported by flutter_blue_plus
    // For full implementation, you'd need to use platform channels
    // This is a placeholder for the advertising logic
    
    _isAdvertising = true;
    
    // Platform-specific advertising would be implemented here using:
    // - Android: AdvertiseSettings, AdvertiseData
    // - iOS: CBPeripheralManager
    
    // For now, we'll just track the state
  }
  
  /// Stop advertising
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    
    // Platform-specific advertising stop would be implemented here
  }
  
  /// Handle scan results
  void _onScanResults(List<ScanResult> results) {
    final now = DateTime.now();
    
    for (final result in results) {
      // Filter by RSSI threshold
      if (result.rssi < BleConstants.rssiThreshold) {
        continue;
      }
      
      // Check if device advertises our service
      final hasService = result.advertisementData.serviceUuids
          .any((uuid) => uuid.toString().toLowerCase() == BleConstants.serviceUuid.toLowerCase());
      
      if (!hasService) {
        continue;
      }
      
      final deviceId = result.device.remoteId.toString();
      final deviceName = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : result.device.platformName.isNotEmpty
              ? result.device.platformName
              : 'Unknown Device';
      
      final bleDevice = BleDevice(
        id: deviceId,
        name: deviceName,
        rssi: result.rssi,
        lastSeen: now,
      );
      
      _discoveredDevices[deviceId] = bleDevice;
    }
    
    // Emit updated device list
    _scanResultsController.add(_discoveredDevices.values.toList());
  }
  
  /// Remove devices not seen in the last 10 seconds
  void _cleanupStaleDevices() {
    final now = DateTime.now();
    final staleThreshold = const Duration(seconds: 10);
    
    _discoveredDevices.removeWhere((key, device) {
      return now.difference(device.lastSeen) > staleThreshold;
    });
    
    // Emit updated device list
    if (_discoveredDevices.isNotEmpty) {
      _scanResultsController.add(_discoveredDevices.values.toList());
    }
  }
  
  /// Get current list of discovered devices
  List<BleDevice> get currentDevices => _discoveredDevices.values.toList();
  
  /// Check if currently scanning
  bool get isScanning => _isScanning;
  
  /// Check if currently advertising
  bool get isAdvertising => _isAdvertising;
  
  /// Dispose resources
  Future<void> dispose() async {
    await stopScanning();
    await stopAdvertising();
    await _scanResultsController.close();
  }
}
