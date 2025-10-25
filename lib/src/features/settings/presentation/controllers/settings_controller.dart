import 'package:flutter/foundation.dart';

import '../../../../app/di/app_dependencies.dart';
import '../../../../core/utils/logger.dart';
import '../../../p2p/data/services/p2p_service.dart';

/// Controller for managing P2P settings and setup.
class SettingsController extends ChangeNotifier {
  SettingsController()
      : _logger = const Logger('SettingsController'),
        _p2pService = AppDependencies.instance.p2pService;

  final Logger _logger;
  final P2pService _p2pService;

  bool _isCheckingPermissions = false;
  bool _isCheckingServices = false;
  bool _allPermissionsGranted = false;
  bool _allServicesEnabled = false;

  bool get isCheckingPermissions => _isCheckingPermissions;
  bool get isCheckingServices => _isCheckingServices;
  bool get allPermissionsGranted => _allPermissionsGranted;
  bool get allServicesEnabled => _allServicesEnabled;
  bool get isP2pReady => _allPermissionsGranted && _allServicesEnabled;

  /// Check and request all necessary permissions.
  Future<void> setupPermissions() async {
    _isCheckingPermissions = true;
    notifyListeners();

    try {
      await _p2pService.checkAndRequestPermissions();
      _allPermissionsGranted = await _p2pService.areAllPermissionsGranted();
      _logger.info('Permissions setup completed: $_allPermissionsGranted');
    } catch (e) {
      _logger.error('Error setting up permissions: $e');
      _allPermissionsGranted = false;
    } finally {
      _isCheckingPermissions = false;
      notifyListeners();
    }
  }

  /// Check and enable all necessary services.
  Future<void> setupServices() async {
    _isCheckingServices = true;
    notifyListeners();

    try {
      await _p2pService.checkAndEnableServices();
      _allServicesEnabled = await _p2pService.areAllServicesEnabled();
      _logger.info('Services setup completed: $_allServicesEnabled');
    } catch (e) {
      _logger.error('Error setting up services: $e');
      _allServicesEnabled = false;
    } finally {
      _isCheckingServices = false;
      notifyListeners();
    }
  }

  /// Refresh the status of permissions and services.
  Future<void> refreshStatus() async {
    try {
      _allPermissionsGranted = await _p2pService.areAllPermissionsGranted();
      _allServicesEnabled = await _p2pService.areAllServicesEnabled();
      notifyListeners();
    } catch (e) {
      _logger.error('Error refreshing status: $e');
    }
  }
}
