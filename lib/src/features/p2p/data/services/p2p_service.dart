import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/logger.dart';

enum P2pSessionRole { host, client }

/// Service responsible for managing P2P connection setup, permissions, and services.
class P2pService {
  P2pService() : _logger = const Logger('P2pService');

  final Logger _logger;

  FlutterP2pHost? _hostInterface;
  bool _hostInitialized = false;

  FlutterP2pClient? _clientInterface;
  bool _clientInitialized = false;

  /// Initialize the P2P interface for the given role.
  Future<void> initialize({P2pSessionRole role = P2pSessionRole.host}) async {
    await _interfaceForRole(role);
  }

  /// Check and request all necessary permissions for P2P functionality.
  Future<void> checkAndRequestPermissions({
    P2pSessionRole role = P2pSessionRole.host,
    bool requestIfMissing = true,
  }) async {
    _logger.info('Checking and requesting permissions for $role');

    final interface = await _interfaceForRole(role);

    await _requestPermissionWithTimeout(
      permission: Permission.locationWhenInUse,
      logLabel: 'location (when in use)',
    );

    await _requestPermissionWithTimeout(
      permission: Permission.nearbyWifiDevices,
      logLabel: 'nearby Wi-Fi devices',
    );

    if (!await _storagePermissionGranted(
      interface: interface,
      requestIfMissing: requestIfMissing,
    )) {
      _logger.info('Requesting storage permission through plugin fallback');
      await interface.askStoragePermission();
      await _storagePermissionGranted(
        interface: interface,
        requestIfMissing: requestIfMissing,
      );
    }

    if (!await interface.checkP2pPermissions()) {
      _logger.info('Requesting P2P permissions');
      await interface.askP2pPermissions();
    }

    if (!await interface.checkBluetoothPermissions()) {
      _logger.info('Requesting Bluetooth permissions');
      await interface.askBluetoothPermissions();
    }

    _logger.info('Permission checks completed for $role');
  }

  /// Check and enable all necessary services for P2P functionality.
  Future<void> checkAndEnableServices({
    P2pSessionRole role = P2pSessionRole.host,
  }) async {
    _logger.info('Checking and enabling services for $role');

    final interface = await _interfaceForRole(role);

    if (!await interface.checkWifiEnabled()) {
      _logger.info('Enabling Wi-Fi services');
      await interface.enableWifiServices();
    }

    if (!await interface.checkLocationEnabled()) {
      _logger.info('Enabling location services');
      await interface.enableLocationServices();
    }

    if (!await interface.checkBluetoothEnabled()) {
      _logger.info('Enabling Bluetooth services');
      await interface.enableBluetoothServices();
    }

    _logger.info('Service checks completed for $role');
  }

  /// Check if all permissions are granted for the requested role.
  Future<bool> areAllPermissionsGranted({
    P2pSessionRole role = P2pSessionRole.host,
    bool requestIfMissing = true,
  }) async {
    final interface = await _interfaceForRole(role);

    final storage = await _storagePermissionGranted(
      interface: interface,
      requestIfMissing: requestIfMissing,
    );
    final p2p = await interface.checkP2pPermissions();
    final bluetooth = await interface.checkBluetoothPermissions();

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
      'Permission status for $role → storage:$storage, p2p:$p2p, '
      'bluetooth:$bluetooth, location:$locationGranted, nearby:$nearbyGranted, '
      'all:$allGranted',
    );

    return allGranted;
  }

  /// Check if all required services are enabled for the requested role.
  Future<bool> areAllServicesEnabled({
    P2pSessionRole role = P2pSessionRole.host,
  }) async {
    final interface = await _interfaceForRole(role);

    final wifi = await interface.checkWifiEnabled();
    final location = await interface.checkLocationEnabled();
    final bluetooth = await interface.checkBluetoothEnabled();
    return wifi && location && bluetooth;
  }

  /// Ensure the host interface is ready for use.
  Future<FlutterP2pHost> ensureHostInitialized() async {
    _hostInterface ??= FlutterP2pHost();
    if (!_hostInitialized) {
      _hostInitialized = true;
      try {
        _logger.info('Initializing P2P host interface');
        await _hostInterface!.initialize();
      } catch (e) {
        _hostInitialized = false;
        rethrow;
      }
    }
    return _hostInterface!;
  }

  /// Ensure the client interface is ready for use.
  Future<FlutterP2pClient> ensureClientInitialized() async {
    _clientInterface ??= FlutterP2pClient();
    if (!_clientInitialized) {
      _clientInitialized = true;
      try {
        _logger.info('Initializing P2P client interface');
        await _clientInterface!.initialize();
      } catch (e) {
        _clientInitialized = false;
        rethrow;
      }
    }
    return _clientInterface!;
  }

  /// Dispose resources linked to the given role.
  Future<void> disposeRole(P2pSessionRole role) async {
    switch (role) {
      case P2pSessionRole.host:
        final host = _hostInterface;
        if (host != null) {
          try {
            await host.dispose();
          } catch (e) {
            _logger.info('Error disposing host interface: $e');
          }
          _hostInterface = null;
          _hostInitialized = false;
        }
        break;
      case P2pSessionRole.client:
        final client = _clientInterface;
        if (client != null) {
          try {
            await client.dispose();
          } catch (e) {
            _logger.info('Error disposing client interface: $e');
          }
          _clientInterface = null;
          _clientInitialized = false;
        }
        break;
    }
  }

  Future<dynamic> _interfaceForRole(P2pSessionRole role) async {
    switch (role) {
      case P2pSessionRole.host:
        return ensureHostInitialized();
      case P2pSessionRole.client:
        return ensureClientInitialized();
    }
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

  Future<bool> _storagePermissionGranted({
    required dynamic interface,
    required bool requestIfMissing,
  }) async {
    if (await interface.checkStoragePermission()) {
      _logger.info('Storage permission already granted via plugin');
      return true;
    }

    // Try the generic storage permission first.
    try {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        _logger.info(
          'Storage permission granted via Permission.storage ($storageStatus)',
        );
        return true;
      }

      if (storageStatus == PermissionStatus.permanentlyDenied &&
          !requestIfMissing) {
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
        await _handleMediaPermission(
          entry.key,
          entry.value,
          requestIfMissing: requestIfMissing,
        ),
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

    if (await interface.checkStoragePermission()) {
      _logger.info('Plugin now reports storage granted after media requests');
      return true;
    }

    try {
      _logger.info('Requesting Permission.storage as fallback');
      final storageResult = await Permission.storage.request();
      if (storageResult.isGranted || storageResult.isLimited) {
        _logger.info(
          'Storage permission granted after fallback request: $storageResult',
        );
        return true;
      }
    } catch (e) {
      _logger.info('Unable to request Permission.storage: $e');
    }

    final finalPluginCheck = await interface.checkStoragePermission();
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
