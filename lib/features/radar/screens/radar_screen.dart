import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/core/models/device_model.dart';
import 'package:aurasync/features/radar/providers/device_state_provider.dart';
import 'package:aurasync/features/radar/widgets/radar_painter.dart';
import 'package:aurasync/features/radar/widgets/device_dot.dart';
import 'package:aurasync/features/radar/widgets/device_card.dart';
import 'package:aurasync/features/audio/widgets/audio_control_panel.dart';
import 'package:aurasync/features/audio/providers/audio_detection_provider.dart';
import 'package:aurasync/features/ble/widgets/ble_control_panel.dart';
import 'package:aurasync/features/ble/providers/ble_state_provider.dart';

/// The main Radar Screen showing discovered devices.
/// Phase 5: Integrated dual-verify logic with auto-connect.
class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _showAudioPanel = false;
  bool _showBlePanel = false;

  @override
  void initState() {
    super.initState();
    // Create rotation animation for radar sweep
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(deviceStateProvider);
    final audioState = ref.watch(audioDetectionProvider);
    final bleState = ref.watch(bleStateProvider);
    final size = MediaQuery.of(context).size;
    final radarSize = math.min(size.width, size.height) * 0.85;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BLE Control Button
          FloatingActionButton(
            heroTag: 'ble_button',
            onPressed: () {
              setState(() {
                _showBlePanel = !_showBlePanel;
                if (_showBlePanel) _showAudioPanel = false;
              });
            },
            backgroundColor: bleState.isScanning || bleState.isAdvertising
                ? const Color(0xFF00AAFF)
                : Colors.grey[700],
            child: Icon(
              _showBlePanel ? Icons.close : Icons.bluetooth,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Audio Control Button
          FloatingActionButton(
            heroTag: 'audio_button',
            onPressed: () {
              setState(() {
                _showAudioPanel = !_showAudioPanel;
                if (_showAudioPanel) _showBlePanel = false;
              });
            },
            backgroundColor: audioState.isListening || audioState.isTransmitting
                ? const Color(0xFF00FFF0)
                : Colors.grey[700],
            child: Icon(
              _showAudioPanel ? Icons.close : Icons.tune,
              color: const Color(0xFF0A0E27),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(devices, audioState),
            
                // Radar Display
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: radarSize,
                      height: radarSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Static radar background (circles and grid)
                          CustomPaint(
                            size: Size(radarSize, radarSize),
                            painter: RadarBackgroundPainter(),
                          ),
                      
                          // Rotating radar sweep
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(radarSize, radarSize),
                                painter: RadarSweepPainter(
                                  rotation: _rotationController.value * 2 * math.pi,
                                ),
                              );
                            },
                          ),
                      
                          // Device dots
                          ...devices.map((device) => _buildDeviceDot(
                            device,
                            radarSize,
                          )),
                      
                          // Center indicator
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FFF0),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FFF0).withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            
                // Device List
                _buildDeviceList(devices),
              ],
            ),
            
            // BLE Control Panel (Overlay)
            if (_showBlePanel)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BleControlPanel(),
              ),
            
            // Audio Control Panel (Overlay)
            if (_showAudioPanel)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AudioControlPanel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<DiscoveredDevice> devices, AudioDetectionState audioState) {
    final dualVerifiedCount = devices.where((d) => d.isDualVerified).length;
    final bleOnlyCount = devices.where((d) => d.isBleVisible && !d.isAudioVerified).length;
    final audioOnlyCount = devices.where((d) => !d.isBleVisible && d.isAudioVerified).length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            '✧ AuraSync ✧',
            style: TextStyle(
              color: Color(0xFF00FFF0),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanning for nearby devices...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip('Dual-Verified', dualVerifiedCount, const Color(0xFF00FF88)),
              _buildStatChip('BLE Only', bleOnlyCount, const Color(0xFF00AAFF)),
              _buildStatChip('Audio Only', audioOnlyCount, const Color(0xFFFF00FF)),
            ],
          ),
          const SizedBox(height: 12),
          // Audio detection indicator
          if (audioState.isListening || audioState.isTransmitting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: audioState.isDetected
                    ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: audioState.isDetected
                      ? const Color(0xFF00FF88).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.audiotrack,
                    size: 14,
                    color: audioState.isDetected
                        ? const Color(0xFF00FF88)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    audioState.isDetected
                        ? 'Audio Detected!'
                        : 'Audio System Active',
                    style: TextStyle(
                      color: audioState.isDetected
                          ? const Color(0xFF00FF88)
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDot(DiscoveredDevice device, double radarSize) {
    // Convert polar coordinates (angle, distance) to Cartesian (x, y)
    final maxRadius = radarSize / 2 - 20; // Leave margin
    final normalizedDistance = (device.distanceEstimate / 5.0).clamp(0.0, 1.0);
    final radius = normalizedDistance * maxRadius;
    
    // Convert angle to radians (0° is top, clockwise)
    final angleRad = (device.angle - 90) * math.pi / 180;
    final x = radius * math.cos(angleRad);
    final y = radius * math.sin(angleRad);

    return Positioned(
      left: radarSize / 2 + x - 12,
      top: radarSize / 2 + y - 12,
      child: DeviceDot(device: device),
    );
  }

  Widget _buildDeviceList(List<DiscoveredDevice> devices) {
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No devices found',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start BLE scan and audio detection to discover nearby devices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return DeviceCard(device: device);
        },
      ),
    );
  }
}
