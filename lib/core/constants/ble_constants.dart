/// BLE Constants for AuraSync
/// 
/// Service UUID: 0000AA00-0000-1000-8000-00805F9B34FB
/// This is the unique identifier for AuraSync devices.
class BleConstants {
  // AuraSync Service UUID
  static const String serviceUuid = '0000AA00-0000-1000-8000-00805F9B34FB';
  
  // Characteristic UUIDs for data exchange
  static const String deviceInfoCharacteristic = '0000AA01-0000-1000-8000-00805F9B34FB';
  static const String messageCharacteristic = '0000AA02-0000-1000-8000-00805F9B34FB';
  
  // Scan settings
  static const int scanDurationSeconds = 5;
  static const int rssiThreshold = -100; // Minimum RSSI to consider
  
  // Advertising settings
  static const String advertisingName = 'AuraSync';
}
