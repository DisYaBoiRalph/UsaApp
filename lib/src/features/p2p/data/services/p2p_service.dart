import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/logger.dart';

/// Service responsible for managing P2P connection setup, permissions, and services.
class P2pService {
  P2pService() : _logger = const Logger('P2pService');

  final Logger _logger;
  FlutterP2pHost? _p2pInterface;

  /// Initialize the P2P interface.
  Future<void> initialize() async {
    if (_p2pInterface != null) {
      _logger.info('P2P service already initialized');
      return;
    }

    _logger.info('Initializing P2P service');
    _p2pInterface = FlutterP2pHost();
  }

  /// Check and request all necessary permissions for P2P functionality.
  Future<void> checkAndRequestPermissions() async {
    _logger.info('Checking and requesting permissions');

    await _requestPermissionWithTimeout(
      permission: Permission.locationWhenInUse,
      logLabel: 'location (when in use)',
    );

    await _requestPermissionWithTimeout(
      permission: Permission.nearbyWifiDevices,
      logLabel: 'nearby Wi-Fi devices',
    );

    // Storage (for file transfer)
  await initialize();

    if (!await _storagePermissionGranted(requestIfMissing: true)) {
      _logger.info('Requesting storage permission through plugin fallback');
      await _p2pInterface!.askStoragePermission();
      await _storagePermissionGranted(requestIfMissing: true);
    }

    // P2P (Wi-Fi Direct related permissions for creating/connecting to groups)
    if (!await _p2pInterface!.checkP2pPermissions()) {
      _logger.info('Requesting P2P permissions');
      await _p2pInterface!.askP2pPermissions();
    }

    // Bluetooth (for BLE discovery and connection)
    if (!await _p2pInterface!.checkBluetoothPermissions()) {
      _logger.info('Requesting Bluetooth permissions');
      await _p2pInterface!.askBluetoothPermissions();
    }

    _logger.info('Permission checks completed');
  }

  /// Check and enable all necessary services for P2P functionality.
  Future<void> checkAndEnableServices() async {
    _logger.info('Checking and enabling services');

    // Wi-Fi
    if (!await _p2pInterface!.checkWifiEnabled()) {
      _logger.info('Enabling Wi-Fi services');
      await _p2pInterface!.enableWifiServices();
    }

    // Location (often needed for scanning)
    if (!await _p2pInterface!.checkLocationEnabled()) {
      _logger.info('Enabling location services');
      await _p2pInterface!.enableLocationServices();
    }

    // Bluetooth (if using BLE features)
    if (!await _p2pInterface!.checkBluetoothEnabled()) {
      _logger.info('Enabling Bluetooth services');
      await _p2pInterface!.enableBluetoothServices();
    }

    _logger.info('Service checks completed');
  }

  /// Check if all permissions are granted.
  Future<bool> areAllPermissionsGranted({bool requestIfMissing = true}) async {
  await initialize();

    final storage = await _storagePermissionGranted(requestIfMissing: requestIfMissing);
  final p2p = await _p2pInterface!.checkP2pPermissions();
  final bluetooth = await _p2pInterface!.checkBluetoothPermissions();

    var locationGranted = true;
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      locationGranted = locationStatus.isGranted || locationStatus.isLimited;

      if (!locationGranted) {
        final legacyLocation = await Permission.location.status;
        locationGranted = legacyLocation.isGranted || legacyLocation.isLimited;
      }
    } catch (e) {
      _logger.info('Unable to determine location permission status: $e');
    }

    var nearbyGranted = true;
    try {
      final nearbyStatus = await Permission.nearbyWifiDevices.status;
      nearbyGranted = nearbyStatus.isGranted || nearbyStatus.isLimited;

      if (!nearbyGranted && !nearbyStatus.isPermanentlyDenied) {
        // Treat as satisfied on platforms that do not expose this permission.
        nearbyGranted = true;
      }
    } catch (e) {
      _logger.info('Unable to determine nearby Wi-Fi permission status: $e');
    }

    final allGranted =
        storage && p2p && bluetooth && locationGranted && nearbyGranted;

    _logger.info(
      'Permission status → storage:$storage, p2p:$p2p, bluetooth:$bluetooth, '
      'location:$locationGranted, nearby:$nearbyGranted, all:$allGranted',
    );

    return allGranted;
  }

  /// Check if all required services are enabled.
  Future<bool> areAllServicesEnabled() async {
    await initialize();

    final wifi = await _p2pInterface!.checkWifiEnabled();
    final location = await _p2pInterface!.checkLocationEnabled();
    final bluetooth = await _p2pInterface!.checkBluetoothEnabled();
    return wifi && location && bluetooth;
  }

  /// Get the P2P interface instance for advanced operations.
  FlutterP2pHost get p2pInterface {
    final instance = _p2pInterface;
    if (instance == null) {
      throw StateError('P2pService.initialize() must be called before accessing p2pInterface');
    }
    return instance;
  }

  Future<void> _requestPermissionWithTimeout({
    required Permission permission,
    required String logLabel,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) {
        _logger.info('$logLabel permission already granted ($status)');
        return;
      }

      _logger.info('Requesting $logLabel permission');
      try {
        final result = await permission.request().timeout(timeout);
        _logger.info('$logLabel permission result: $result');
      } on TimeoutException {
        _logger.info('$logLabel permission request timed out');
      }
    } catch (e) {
      _logger.info('Unable to request $logLabel permission: $e');
    }
  }

  Future<bool> _storagePermissionGranted({required bool requestIfMissing}) async {
    await initialize();

    if (await _p2pInterface!.checkStoragePermission()) {
      _logger.info('Storage permission already granted via plugin');
      return true;
    }

    // Try the generic storage permission first.
    try {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        _logger.info('Storage permission granted via Permission.storage ($storageStatus)');
        return true;
      }

      if (storageStatus == PermissionStatus.permanentlyDenied && !requestIfMissing) {
        _logger.info('Storage permission permanently denied');
        return false;
      }
    } catch (e) {
      _logger.info('Unable to query Permission.storage status: $e');
    }

    // Check Android 13 scoped media permissions (images/videos/audio) without prompting unless requested.
    final mediaStatuses = <Permission, String>{
      Permission.photos: 'photos',
      Permission.videos: 'videos',
      Permission.audio: 'audio',
    };

    final mediaResults = <bool>[];

    for (final entry in mediaStatuses.entries) {
      mediaResults.add(
        await _handleMediaPermission(entry.key, entry.value, requestIfMissing: requestIfMissing),
      );
    }

    final mediaGranted = mediaResults.every((granted) => granted);

    if (mediaGranted) {
      _logger.info('Scoped media permissions granted');
      return true;
    }

    if (!requestIfMissing) {
      _logger.info('Storage permission not granted yet (passive check)');
      return false;
    }

    if (await _p2pInterface!.checkStoragePermission()) {
      _logger.info('Plugin now reports storage granted after media requests');
      return true;
    }

    try {
      _logger.info('Requesting Permission.storage as fallback');
      final storageResult = await Permission.storage.request();
      if (storageResult.isGranted || storageResult.isLimited) {
        _logger.info('Storage permission granted after fallback request: $storageResult');
        return true;
      }
    } catch (e) {
      _logger.info('Unable to request Permission.storage: $e');
    }

    final finalPluginCheck = await _p2pInterface!.checkStoragePermission();
    _logger.info('Final plugin storage check result: $finalPluginCheck');

    return finalPluginCheck;
  }

  Future<bool> _handleMediaPermission(
    Permission permission,
    String label, {
    required bool requestIfMissing,
  }) async {
    try {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) {
        _logger.info('$label media permission already granted ($status)');
        return true;
      }

      if (!requestIfMissing) {
        _logger.info('$label media permission not granted (passive check)');
        return false;
      }

      _logger.info('Requesting $label media permission');
      final result = await permission.request();
      final granted = result.isGranted || result.isLimited;
      _logger.info('$label media permission result: $result');
      return granted;
    } on MissingPluginException catch (_) {
      // Not supported on this platform/version; do not block the flow.
      _logger.info('$label media permission not supported, skipping');
      return true;
    } catch (e) {
      _logger.info('Error requesting $label media permission: $e');
      return false;
    }
  }
}
