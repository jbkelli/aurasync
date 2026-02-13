import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasync/features/permissions/providers/permission_provider.dart';
import 'package:aurasync/features/permissions/screens/permission_request_screen.dart';
import 'package:aurasync/features/radar/screens/radar_screen.dart';

/// Root widget that handles permission flow.
/// Shows PermissionRequestScreen if permissions are not granted,
/// otherwise shows the main RadarScreen.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionProvider);

    // Show loading indicator while checking permissions
    if (permissionState.isLoading && !permissionState.allGranted) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✧ AuraSync ✧',
                style: TextStyle(
                  color: Color(0xFF00FFF0),
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                color: Color(0xFF00FFF0),
              ),
              SizedBox(height: 20),
              Text(
                'Checking permissions...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show main app if all permissions granted
    if (permissionState.allGranted) {
      return const RadarScreen();
    }

    // Show permission request screen
    return const PermissionRequestScreen();
  }
}
