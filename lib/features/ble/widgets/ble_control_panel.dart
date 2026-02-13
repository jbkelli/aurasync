import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/features/ble/providers/ble_state_provider.dart';

/// BLE Control Panel Widget
/// Provides controls for BLE scanning and advertising
class BleControlPanel extends ConsumerWidget {
  const BleControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);
    final bleNotifier = ref.read(bleStateProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.bluetooth,
                color: bleState.isBluetoothAvailable ? Colors.blue : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'BLE Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bluetooth Status
          _buildStatusRow(
            icon: Icons.bluetooth_connected,
            label: 'Bluetooth',
            value: bleState.isBluetoothAvailable ? 'Available' : 'Off',
            color: bleState.isBluetoothAvailable ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 12),

          // Scan Status
          _buildStatusRow(
            icon: Icons.radar,
            label: 'Scanning',
            value: bleState.isScanning ? 'Active' : 'Stopped',
            color: bleState.isScanning ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 12),

          // Advertising Status
          _buildStatusRow(
            icon: Icons.broadcast_on_personal,
            label: 'Advertising',
            value: bleState.isAdvertising ? 'Active' : 'Stopped',
            color: bleState.isAdvertising ? Colors.purple : Colors.grey,
          ),
          const SizedBox(height: 12),

          // Discovered Devices Count
          _buildStatusRow(
            icon: Icons.devices,
            label: 'Devices Found',
            value: bleState.discoveredDevices.length.toString(),
            color: bleState.discoveredDevices.isNotEmpty ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 24),

          // Error Message
          if (bleState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bleState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Control Buttons
          Row(
            children: [
              // Start/Stop Scanning
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: bleState.isBluetoothAvailable
                      ? () {
                          if (bleState.isScanning) {
                            bleNotifier.stopScanning();
                          } else {
                            bleNotifier.startScanning();
                          }
                        }
                      : null,
                  icon: Icon(
                    bleState.isScanning ? Icons.stop : Icons.radar,
                  ),
                  label: Text(bleState.isScanning ? 'Stop Scan' : 'Start Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bleState.isScanning
                        ? Colors.red.withValues(alpha: 0.8)
                        : Colors.blue.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Start/Stop Advertising
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: bleState.isBluetoothAvailable
                      ? () {
                          if (bleState.isAdvertising) {
                            bleNotifier.stopAdvertising();
                          } else {
                            bleNotifier.startAdvertising();
                          }
                        }
                      : null,
                  icon: Icon(
                    bleState.isAdvertising ? Icons.stop : Icons.broadcast_on_personal,
                  ),
                  label: Text(bleState.isAdvertising ? 'Stop Adv' : 'Start Adv'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bleState.isAdvertising
                        ? Colors.red.withValues(alpha: 0.8)
                        : Colors.purple.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Refresh Bluetooth Status Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => bleNotifier.checkBluetoothStatus(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Bluetooth Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Device List
          if (bleState.discoveredDevices.isNotEmpty) ...[
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Discovered Devices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bleState.discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = bleState.discoveredDevices[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'RSSI: ${device.rssi} dBm',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Distance: ${device.estimatedDistance.toStringAsFixed(1)}m',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
