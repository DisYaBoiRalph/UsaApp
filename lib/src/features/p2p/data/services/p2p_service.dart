import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

import '../../../../core/utils/logger.dart';

/// Service responsible for managing P2P connection setup, permissions, and services.
class P2pService {
  P2pService() : _logger = const Logger('P2pService');

  final Logger _logger;
  late final FlutterP2pHost _p2pInterface;

  /// Initialize the P2P interface.
  Future<void> initialize() async {
    _logger.info('Initializing P2P service');
    _p2pInterface = FlutterP2pHost();
  }

  /// Check and request all necessary permissions for P2P functionality.
  Future<void> checkAndRequestPermissions() async {
    _logger.info('Checking and requesting permissions');

    // Storage (for file transfer)
    if (!await _p2pInterface.checkStoragePermission()) {
      _logger.info('Requesting storage permission');
      await _p2pInterface.askStoragePermission();
    }

    // P2P (Wi-Fi Direct related permissions for creating/connecting to groups)
    if (!await _p2pInterface.checkP2pPermissions()) {
      _logger.info('Requesting P2P permissions');
      await _p2pInterface.askP2pPermissions();
    }

    // Bluetooth (for BLE discovery and connection)
    if (!await _p2pInterface.checkBluetoothPermissions()) {
      _logger.info('Requesting Bluetooth permissions');
      await _p2pInterface.askBluetoothPermissions();
    }

    _logger.info('Permission checks completed');
  }

  /// Check and enable all necessary services for P2P functionality.
  Future<void> checkAndEnableServices() async {
    _logger.info('Checking and enabling services');

    // Wi-Fi
    if (!await _p2pInterface.checkWifiEnabled()) {
      _logger.info('Enabling Wi-Fi services');
      await _p2pInterface.enableWifiServices();
    }

    // Location (often needed for scanning)
    if (!await _p2pInterface.checkLocationEnabled()) {
      _logger.info('Enabling location services');
      await _p2pInterface.enableLocationServices();
    }

    // Bluetooth (if using BLE features)
    if (!await _p2pInterface.checkBluetoothEnabled()) {
      _logger.info('Enabling Bluetooth services');
      await _p2pInterface.enableBluetoothServices();
    }

    _logger.info('Service checks completed');
  }

  /// Check if all permissions are granted.
  Future<bool> areAllPermissionsGranted() async {
    final storage = await _p2pInterface.checkStoragePermission();
    final p2p = await _p2pInterface.checkP2pPermissions();
    final bluetooth = await _p2pInterface.checkBluetoothPermissions();
    return storage && p2p && bluetooth;
  }

  /// Check if all required services are enabled.
  Future<bool> areAllServicesEnabled() async {
    final wifi = await _p2pInterface.checkWifiEnabled();
    final location = await _p2pInterface.checkLocationEnabled();
    final bluetooth = await _p2pInterface.checkBluetoothEnabled();
    return wifi && location && bluetooth;
  }

  /// Get the P2P interface instance for advanced operations.
  FlutterP2pHost get p2pInterface => _p2pInterface;
}
