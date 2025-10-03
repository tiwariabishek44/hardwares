import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/login/login_controller.dart';
import 'package:hardwares/app/utils/enhance_firebase_sync_servicer.dart';

class EnhancedConnectivityService extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  var connectionType = ConnectivityResult.none.obs;
  var isConnected = false.obs;
  var isWifiConnected = false.obs;
  var autoSyncEnabled = true.obs;

  final EnhancedFirebaseSyncService _syncService =
      EnhancedFirebaseSyncService();

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      log('Could not check connectivity status: $e');
      return;
    }
    return _updateConnectionStatus(result);
  }

  // Update connection status and trigger sync if WiFi connected
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    connectionType.value = result;

    switch (result) {
      case ConnectivityResult.wifi:
        isConnected.value = true;
        isWifiConnected.value = true;
        _onWifiConnected();
        break;
      case ConnectivityResult.mobile:
        isConnected.value = true;
        isWifiConnected.value = false;
        _onMobileConnected();
        break;
      case ConnectivityResult.ethernet:
        isConnected.value = true;
        isWifiConnected.value = false;
        _onEthernetConnected();
        break;
      case ConnectivityResult.none:
        isConnected.value = false;
        isWifiConnected.value = false;
        _onDisconnected();
        break;
      default:
        isConnected.value = false;
        isWifiConnected.value = false;
        break;
    }
  }

  // When WiFi connected - trigger auto sync
  void _onWifiConnected() async {
    log('📶 WiFi connected - checking for data to sync');

    Get.snackbar(
      '📶 WiFi Connected',
      'Connected to WiFi network',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
    );

    // Auto-sync if enabled and user is logged in
    if (autoSyncEnabled.value) {
      await _triggerAutoSync();
    }
  }

  // When mobile data connected
  void _onMobileConnected() {
    log('📶 Mobile data connected');

    Get.snackbar(
      '📱 Mobile Connected',
      'Connected via mobile data',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
    );
  }

  // When ethernet connected
  void _onEthernetConnected() {
    log('📶 Ethernet connected');

    Get.snackbar(
      '🔌 Ethernet Connected',
      'Connected via ethernet',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
    );

    // Also trigger sync for ethernet
    if (autoSyncEnabled.value) {
      _triggerAutoSync();
    }
  }

  // When disconnected
  void _onDisconnected() {
    log('📵 Disconnected from internet');

    Get.snackbar(
      '📵 Offline',
      'Working in offline mode',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
    );
  }

  // Trigger automatic sync
  Future<void> _triggerAutoSync() async {
    try {
      // Check if user is logged in
      final loginController = Get.find<LoginController>();
      if (!loginController.isLoggedIn()) {
        log('User not logged in, skipping auto sync');
        return;
      }

      String plumberId = loginController.getPlumberId();
      if (plumberId.isEmpty) {
        log('No plumber ID found, skipping auto sync');
        return;
      }

      // Add a small delay to ensure connection is stable
      await Future.delayed(Duration(seconds: 2));

      log('🔄 Triggering auto sync for plumber: $plumberId');

      // Start the comprehensive sync
      await _syncService.uploadAllUnsyncedData(plumberId);
    } catch (e) {
      log('❌ Error during auto sync: $e');
    }
  }

  // Manual sync trigger
  Future<void> triggerManualSync() async {
    try {
      if (!isConnected.value) {
        Get.snackbar(
          '📵 No Internet',
          'Please connect to internet to sync data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }

      final loginController = Get.find<LoginController>();
      if (!loginController.isLoggedIn()) {
        Get.snackbar(
          '🔐 Not Logged In',
          'Please log in to sync data',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String plumberId = loginController.getPlumberId();
      await _syncService.uploadAllUnsyncedData(plumberId);
    } catch (e) {
      log('❌ Error during manual sync: $e');
      Get.snackbar(
        '❌ Sync Failed',
        'Failed to sync data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  // Get connection type string
  String getConnectionTypeString() {
    switch (connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
