import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/features/audio/providers/audio_detection_provider.dart';

/// Debug control panel for audio system testing.
/// Shows audio status and provides manual controls.
class AudioControlPanel extends ConsumerWidget {
  const AudioControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioDetectionProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FFF0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: const Color(0xFF00FFF0),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Audio System',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Detection indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: audioState.isDetected
                      ? const Color(0xFF00FF88)
                      : Colors.grey.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: audioState.isDetected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00FF88).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status indicators
          _buildStatusRow(
            '🎤 Listening',
            audioState.isListening,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            '📡 Transmitting',
            audioState.isTransmitting,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            '✓ Detection',
            audioState.isDetected,
          ),
          
          // Detection details
          if (audioState.lastPeakFrequency != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Text(
              'Peak: ${audioState.lastPeakFrequency!.toStringAsFixed(0)} Hz',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Magnitude: ${audioState.lastPeakMagnitude!.toStringAsFixed(3)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
          
          // Error message
          if (audioState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                audioState.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context: context,
                  label: audioState.isListening ? 'Stop RX' : 'Start RX',
                  icon: Icons.mic,
                  isActive: audioState.isListening,
                  onPressed: () {
                    ref.read(audioDetectionProvider.notifier).toggleReceiver();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  context: context,
                  label: audioState.isTransmitting ? 'Stop TX' : 'Start TX',
                  icon: Icons.speaker,
                  isActive: audioState.isTransmitting,
                  onPressed: () {
                    ref.read(audioDetectionProvider.notifier).toggleTransmitter();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Start/Stop All button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final notifier = ref.read(audioDetectionProvider.notifier);
                if (audioState.isListening || audioState.isTransmitting) {
                  await notifier.stop();
                } else {
                  await notifier.start();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: (audioState.isListening || audioState.isTransmitting)
                    ? Colors.red.withValues(alpha: 0.2)
                    : const Color(0xFF00FFF0).withValues(alpha: 0.2),
                foregroundColor: (audioState.isListening || audioState.isTransmitting)
                    ? Colors.red
                    : const Color(0xFF00FFF0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                (audioState.isListening || audioState.isTransmitting)
                    ? 'Stop All'
                    : 'Start All',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          isActive ? 'ON' : 'OFF',
          style: TextStyle(
            color: isActive ? const Color(0xFF00FF88) : Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? const Color(0xFF00FFF0).withValues(alpha: 0.2)
            : const Color(0xFF1A1F3A),
        foregroundColor: isActive
            ? const Color(0xFF00FFF0)
            : Colors.white.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive
                ? const Color(0xFF00FFF0).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
