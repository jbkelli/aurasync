import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/features/ble/services/ble_service.dart';

/// State for BLE functionality
class BleState {
  final bool isScanning;
  final bool isAdvertising;
  final bool isBluetoothAvailable;
  final List<BleDevice> discoveredDevices;
  final String? errorMessage;
  
  const BleState({
    this.isScanning = false,
    this.isAdvertising = false,
    this.isBluetoothAvailable = false,
    this.discoveredDevices = const [],
    this.errorMessage,
  });
  
  BleState copyWith({
    bool? isScanning,
    bool? isAdvertising,
    bool? isBluetoothAvailable,
    List<BleDevice>? discoveredDevices,
    String? errorMessage,
  }) {
    return BleState(
      isScanning: isScanning ?? this.isScanning,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isBluetoothAvailable: isBluetoothAvailable ?? this.isBluetoothAvailable,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for BLE state management
class BleStateNotifier extends Notifier<BleState> {
  BleService? _bleService;
  StreamSubscription<List<BleDevice>>? _deviceStreamSubscription;
  
  @override
  BleState build() {
    // Initialize BLE service
    _initializeBleService();
    
    // Register cleanup
    ref.onDispose(() {
      _deviceStreamSubscription?.cancel();
      _bleService?.dispose();
    });
    
    return const BleState();
  }
  
  Future<void> _initializeBleService() async {
    _bleService = BleService();
    
    // Check if Bluetooth is available
    final isAvailable = await _bleService!.isBluetoothAvailable();
    state = state.copyWith(isBluetoothAvailable: isAvailable);
    
    // Listen to device stream
    _deviceStreamSubscription = _bleService!.deviceStream.listen(
      (devices) {
        state = state.copyWith(
          discoveredDevices: devices,
          errorMessage: null,
        );
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: error.toString(),
        );
      },
    );
  }
  
  /// Start BLE scanning
  Future<void> startScanning() async {
    if (_bleService == null) {
      return;
    }
    
    try {
      state = state.copyWith(errorMessage: null);
      await _bleService!.startScanning();
      
      state = state.copyWith(
        isScanning: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to start scanning: ${e.toString()}',
      );
    }
  }
  
  /// Stop BLE scanning
  Future<void> stopScanning() async {
    if (_bleService == null) {
      return;
    }
    
    try {
      await _bleService!.stopScanning();
      
      state = state.copyWith(
        isScanning: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop scanning: ${e.toString()}',
      );
    }
  }
  
  /// Start BLE advertising
  Future<void> startAdvertising() async {
    if (_bleService == null) {
      return;
    }
    
    try {
      state = state.copyWith(errorMessage: null);
      await _bleService!.startAdvertising();
      
      state = state.copyWith(
        isAdvertising: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isAdvertising: false,
        errorMessage: 'Failed to start advertising: ${e.toString()}',
      );
    }
  }
  
  /// Stop BLE advertising
  Future<void> stopAdvertising() async {
    if (_bleService == null) {
      return;
    }
    
    try {
      await _bleService!.stopAdvertising();
      
      state = state.copyWith(
        isAdvertising: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop advertising: ${e.toString()}',
      );
    }
  }
  
  /// Check and update Bluetooth availability
  Future<void> checkBluetoothStatus() async {
    if (_bleService == null) {
      return;
    }
    
    final isAvailable = await _bleService!.isBluetoothAvailable();
    state = state.copyWith(isBluetoothAvailable: isAvailable);
  }
}

/// Global provider for BLE state
final bleStateProvider = NotifierProvider<BleStateNotifier, BleState>(() {
  return BleStateNotifier();
});
