import 'package:flutter/material.dart';
import 'package:aurasync/core/models/device_model.dart';

/// A widget representing a device as a dot on the radar
class DeviceDot extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceDot({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on device state
    Color dotColor;
    double dotSize;

    if (device.isDualVerified) {
      dotColor = const Color(0xFF00FF88); // Green for dual-verified
      dotSize = 24;
    } else if (device.isBleVisible) {
      dotColor = const Color(0xFF00AAFF); // Blue for BLE only
      dotSize = 20;
    } else if (device.isAudioVerified) {
      dotColor = const Color(0xFFFF00FF); // Magenta for audio only
      dotSize = 20;
    } else {
      dotColor = Colors.white.withValues(alpha: 0.3);
      dotSize = 16;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: device.isDualVerified
                ? const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
