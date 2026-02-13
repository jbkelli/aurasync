import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/core/models/device_model.dart' as models;
import 'package:aurasync/features/radar/providers/device_state_provider.dart';

/// Enhanced device card showing dual-verify status
class DeviceCard extends ConsumerWidget {
  final models.DiscoveredDevice device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(deviceStateProvider.notifier);
    final verificationStatus = notifier.getVerificationStatus(device);
    final confidenceScore = notifier.getConfidenceScore(device);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
        boxShadow: device.isDualVerified
            ? [
                BoxShadow(
                  color: _getBorderColor().withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context, notifier),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Name + Connection Button
                Row(
                  children: [
                    // Device icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getIconBackgroundColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getDeviceIcon(),
                        color: _getBorderColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Device name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verificationStatus,
                            style: TextStyle(
                              color: _getStatusTextColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Connection button
                    _buildConnectionButton(notifier),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Divider
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                
                const SizedBox(height: 12),
                
                // Status indicators
                Row(
                  children: [
                    // BLE status
                    _buildStatusChip(
                      icon: Icons.bluetooth,
                      label: 'BLE',
                      isActive: device.isBleVisible,
                      color: const Color(0xFF00AAFF),
                    ),
                    const SizedBox(width: 8),
                    
                    // Audio status
                    _buildStatusChip(
                      icon: Icons.graphic_eq,
                      label: 'Audio',
                      isActive: device.isAudioVerified,
                      color: const Color(0xFFFF00FF),
                    ),
                    const SizedBox(width: 8),
                    
                    // Dual-verify status
                    if (device.isDualVerified)
                      _buildStatusChip(
                        icon: Icons.verified,
                        label: 'Verified',
                        isActive: true,
                        color: const Color(0xFF00FF88),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Device details
                Row(
                  children: [
                    // RSSI
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.signal_cellular_alt,
                        label: 'Signal',
                        value: '${device.signalStrength} dBm',
                      ),
                    ),
                    
                    // Distance
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: '${device.distanceEstimate.toStringAsFixed(1)}m',
                      ),
                    ),
                    
                    // Confidence
                    if (device.isDualVerified)
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.analytics,
                          label: 'Confidence',
                          value: '${(confidenceScore * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionButton(DeviceStateNotifier notifier) {
    IconData icon;
    Color color;
    String tooltip;
    VoidCallback? onPressed;

    switch (device.connectionState) {
      case models.ConnectionState.connected:
        icon = Icons.link_off;
        color = Colors.red;
        tooltip = 'Disconnect';
        onPressed = () => notifier.disconnectFromDevice(device);
        break;
      case models.ConnectionState.connecting:
        icon = Icons.sync;
        color = Colors.orange;
        tooltip = 'Connecting...';
        onPressed = null;
        break;
      case models.ConnectionState.disconnected:
        icon = Icons.link;
        color = device.isDualVerified ? const Color(0xFF00FF88) : Colors.grey;
        tooltip = device.isDualVerified ? 'Connect' : 'Not verified';
        onPressed = device.isDualVerified ? () => notifier.connectToDevice(device) : null;
        break;
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: color,
      tooltip: tooltip,
      iconSize: 28,
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? color : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.6),
          size: 16,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, DeviceStateNotifier notifier) {
    // Show device details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E3E),
        title: Text(
          device.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('ID', device.id),
            _buildDialogRow('Status', notifier.getVerificationStatus(device)),
            _buildDialogRow('BLE Visible', device.isBleVisible ? 'Yes' : 'No'),
            _buildDialogRow('Audio Verified', device.isAudioVerified ? 'Yes' : 'No'),
            _buildDialogRow('Signal Strength', '${device.signalStrength} dBm'),
            _buildDialogRow('Distance', '${device.distanceEstimate.toStringAsFixed(2)}m'),
            _buildDialogRow(
              'Confidence',
              '${(notifier.getConfidenceScore(device) * 100).toStringAsFixed(1)}%',
            ),
            _buildDialogRow('Connection', device.connectionState.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (device.isDualVerified) {
      return const Color(0xFF00FF88).withValues(alpha: 0.08);
    } else if (device.isBleVisible && device.isAudioVerified) {
      return const Color(0xFF00AAFF).withValues(alpha: 0.08);
    }
    return Colors.white.withValues(alpha: 0.03);
  }

  Color _getBorderColor() {
    if (device.isDualVerified) {
      return const Color(0xFF00FF88); // Green for dual-verified
    } else if (device.isBleVisible && device.isAudioVerified) {
      return const Color(0xFF00AAFF); // Blue for both signals
    } else if (device.isBleVisible) {
      return const Color(0xFF00AAFF); // Blue for BLE only
    } else if (device.isAudioVerified) {
      return const Color(0xFFFF00FF); // Magenta for audio only
    }
    return Colors.grey;
  }

  Color _getIconBackgroundColor() {
    return _getBorderColor().withValues(alpha: 0.15);
  }

  Color _getStatusTextColor() {
    if (device.isDualVerified) {
      return const Color(0xFF00FF88);
    }
    return Colors.white.withValues(alpha: 0.7);
  }

  IconData _getDeviceIcon() {
    if (device.name.toLowerCase().contains('phone')) {
      return Icons.phone_android;
    } else if (device.name.toLowerCase().contains('laptop') ||
        device.name.toLowerCase().contains('computer')) {
      return Icons.laptop;
    } else if (device.name.toLowerCase().contains('tablet')) {
      return Icons.tablet;
    }
    return Icons.devices;
  }
}
