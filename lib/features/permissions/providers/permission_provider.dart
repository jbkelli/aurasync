import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aurasync/core/services/permission_service.dart';

/// Represents the state of all app permissions
class PermissionState {
  final bool allGranted;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, bool> individualPermissions;

  const PermissionState({
    this.allGranted = false,
    this.isLoading = false,
    this.errorMessage,
    this.individualPermissions = const {},
  });

  PermissionState copyWith({
    bool? allGranted,
    bool? isLoading,
    String? errorMessage,
    Map<String, bool>? individualPermissions,
  }) {
    return PermissionState(
      allGranted: allGranted ?? this.allGranted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      individualPermissions: individualPermissions ?? this.individualPermissions,
    );
  }
}

/// Notifier for managing permission state
class PermissionNotifier extends Notifier<PermissionState> {
  final _service = PermissionService();

  @override
  PermissionState build() {
    // Check permissions on initialization
    _checkPermissions();
    return const PermissionState(isLoading: true);
  }

  /// Check current permission status
  Future<void> _checkPermissions() async {
    try {
      final allGranted = await _service.areAllPermissionsGranted();
      final detailed = await _service.getDetailedStatus();
      
      final individualPermissions = <String, bool>{};
      for (var entry in detailed.entries) {
        individualPermissions[entry.key] = entry.value == PermissionStatus.granted;
      }

      state = PermissionState(
        allGranted: allGranted,
        isLoading: false,
        individualPermissions: individualPermissions,
      );
    } catch (e) {
      state = PermissionState(
        allGranted: false,
        isLoading: false,
        errorMessage: 'Failed to check permissions: $e',
      );
    }
  }

  /// Request all permissions
  Future<bool> requestPermissions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.requestAllPermissions();
      
      if (result.allGranted) {
        await _checkPermissions();
        return true;
      } else if (result.anyPermanentlyDenied) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Some permissions are permanently denied. Please enable them in Settings.',
        );
        return false;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.getSummary(),
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to request permissions: $e',
      );
      return false;
    }
  }

  /// Open app settings
  Future<void> openSettings() async {
    await _service.openSettings();
  }

  /// Refresh permission status
  Future<void> refresh() async {
    await _checkPermissions();
  }
}

/// Provider for permission state
final permissionProvider = NotifierProvider<PermissionNotifier, PermissionState>(
  PermissionNotifier.new,
);
