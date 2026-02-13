import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/features/permissions/providers/permission_provider.dart';

/// Screen shown when permissions need to be requested.
/// Displays beautiful UI explaining why each permission is needed.
class PermissionRequestScreen extends ConsumerWidget {
  const PermissionRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // App Logo/Title
              const Text(
                '✧ AuraSync ✧',
                style: TextStyle(
                  color: Color(0xFF00FFF0),
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Secure Proximity Discovery',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Permission Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      icon: Icons.bluetooth,
                      title: 'Bluetooth',
                      description: 'Discover nearby devices using BLE technology',
                      color: const Color(0xFF00AAFF),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      icon: Icons.mic,
                      title: 'Microphone',
                      description: 'Verify physical proximity using ultrasonic audio (18kHz)',
                      color: const Color(0xFF00FF88),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      icon: Icons.location_on,
                      title: 'Location',
                      description: 'Required for Bluetooth scanning on Android',
                      color: const Color(0xFFFF00FF),
                    ),
                  ],
                ),
              ),
              
              // Error Message
              if (permissionState.errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          permissionState.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action Buttons
              if (permissionState.errorMessage?.contains('permanently denied') ?? false) ...[
                _buildActionButton(
                  context: context,
                  label: 'Open Settings',
                  onPressed: () {
                    ref.read(permissionProvider.notifier).openSettings();
                  },
                  isLoading: false,
                  icon: Icons.settings,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  label: 'Check Again',
                  onPressed: () {
                    ref.read(permissionProvider.notifier).refresh();
                  },
                  isLoading: false,
                  isSecondary: true,
                ),
              ] else ...[
                _buildActionButton(
                  context: context,
                  label: permissionState.isLoading 
                      ? 'Requesting Permissions...' 
                      : 'Grant Permissions',
                  onPressed: permissionState.isLoading
                      ? null
                      : () async {
                          await ref.read(permissionProvider.notifier).requestPermissions();
                        },
                  isLoading: permissionState.isLoading,
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Privacy Note
              Text(
                'Your privacy matters. All data stays on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    bool isSecondary = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary 
              ? const Color(0xFF1A1F3A) 
              : const Color(0xFF00FFF0),
          foregroundColor: isSecondary 
              ? const Color(0xFF00FFF0) 
              : const Color(0xFF0A0E27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary 
                ? BorderSide(color: const Color(0xFF00FFF0).withValues(alpha: 0.3))
                : BorderSide.none,
          ),
          elevation: isSecondary ? 0 : 8,
          shadowColor: isSecondary 
              ? Colors.transparent 
              : const Color(0xFF00FFF0).withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0E27)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSecondary 
                          ? const Color(0xFF00FFF0) 
                          : const Color(0xFF0A0E27),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
