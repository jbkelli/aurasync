import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Service to handle all permission requests for AuraSync.
/// Manages: Microphone, Bluetooth (Scan/Connect), and Location permissions.
class PermissionService {
  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final microphone = await Permission.microphone.isGranted;
    final bluetoothScan = await _checkBluetoothScan();
    final bluetoothConnect = await _checkBluetoothConnect();
    final location = await _checkLocation();

    return microphone && bluetoothScan && bluetoothConnect && location;
  }

  /// Request all required permissions at once
  Future<PermissionRequestResult> requestAllPermissions() async {
    final results = <PermissionType, PermissionStatus>{};

    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    results[PermissionType.microphone] = micStatus;

    // Request Bluetooth permissions (Android 12+)
    if (Platform.isAndroid) {
      final scanStatus = await Permission.bluetoothScan.request();
      results[PermissionType.bluetoothScan] = scanStatus;

      final connectStatus = await Permission.bluetoothConnect.request();
      results[PermissionType.bluetoothConnect] = connectStatus;

      // Location is required for BLE scanning on Android < 12
      final locationStatus = await Permission.location.request();
      results[PermissionType.location] = locationStatus;
    } else if (Platform.isIOS) {
      // iOS handles Bluetooth permissions automatically
      final bluetoothStatus = await Permission.bluetooth.request();
      results[PermissionType.bluetooth] = bluetoothStatus;
    }

    return PermissionRequestResult(results);
  }

  /// Check individual permission: Microphone
  Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  /// Request microphone permission
  Future<PermissionStatus> requestMicrophone() async {
    return await Permission.microphone.request();
  }

  /// Check individual permission: Bluetooth Scan
  Future<bool> isBluetoothScanGranted() async {
    return await _checkBluetoothScan();
  }

  /// Check individual permission: Bluetooth Connect
  Future<bool> isBluetoothConnectGranted() async {
    return await _checkBluetoothConnect();
  }

  /// Check individual permission: Location
  Future<bool> isLocationGranted() async {
    return await _checkLocation();
  }

  /// Open app settings (for when permissions are permanently denied)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // Private helper methods

  Future<bool> _checkBluetoothScan() async {
    if (Platform.isAndroid) {
      return await Permission.bluetoothScan.isGranted;
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }
    return true; // Other platforms don't need this
  }

  Future<bool> _checkBluetoothConnect() async {
    if (Platform.isAndroid) {
      return await Permission.bluetoothConnect.isGranted;
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }
    return true;
  }

  Future<bool> _checkLocation() async {
    if (Platform.isAndroid) {
      // Android needs location for BLE scanning
      return await Permission.location.isGranted;
    }
    // iOS doesn't require location for BLE
    return true;
  }

  /// Check if any permission was permanently denied
  Future<bool> hasAnyPermanentlyDenied() async {
    final microphone = await Permission.microphone.isPermanentlyDenied;
    
    if (Platform.isAndroid) {
      final bluetoothScan = await Permission.bluetoothScan.isPermanentlyDenied;
      final bluetoothConnect = await Permission.bluetoothConnect.isPermanentlyDenied;
      final location = await Permission.location.isPermanentlyDenied;
      return microphone || bluetoothScan || bluetoothConnect || location;
    } else if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.isPermanentlyDenied;
      return microphone || bluetooth;
    }
    
    return microphone;
  }

  /// Get detailed permission status for debugging
  Future<Map<String, PermissionStatus>> getDetailedStatus() async {
    final status = <String, PermissionStatus>{};
    
    status['microphone'] = await Permission.microphone.status;
    
    if (Platform.isAndroid) {
      status['bluetoothScan'] = await Permission.bluetoothScan.status;
      status['bluetoothConnect'] = await Permission.bluetoothConnect.status;
      status['location'] = await Permission.location.status;
    } else if (Platform.isIOS) {
      status['bluetooth'] = await Permission.bluetooth.status;
    }
    
    return status;
  }
}

/// Enum for permission types
enum PermissionType {
  microphone,
  bluetoothScan,
  bluetoothConnect,
  bluetooth, // For iOS
  location,
}

/// Result of permission requests
class PermissionRequestResult {
  final Map<PermissionType, PermissionStatus> results;

  PermissionRequestResult(this.results);

  /// Check if all requested permissions were granted
  bool get allGranted {
    return results.values.every((status) => status.isGranted);
  }

  /// Check if any permission was permanently denied
  bool get anyPermanentlyDenied {
    return results.values.any((status) => status.isPermanentlyDenied);
  }

  /// Get list of denied permissions
  List<PermissionType> get deniedPermissions {
    return results.entries
        .where((entry) => entry.value.isDenied)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get list of permanently denied permissions
  List<PermissionType> get permanentlyDeniedPermissions {
    return results.entries
        .where((entry) => entry.value.isPermanentlyDenied)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get human-readable summary
  String getSummary() {
    if (allGranted) {
      return 'All permissions granted';
    } else if (anyPermanentlyDenied) {
      return 'Some permissions permanently denied. Please enable them in Settings.';
    } else {
      return 'Some permissions were denied: ${deniedPermissions.map((p) => p.name).join(", ")}';
    }
  }
}
