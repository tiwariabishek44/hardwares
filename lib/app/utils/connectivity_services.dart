import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  // Connectivity status
  var isConnected = false.obs;
  var connectionType = ConnectivityResult.none.obs;

  // Connectivity instance
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initialize connectivity
  Future<void> _initConnectivity() async {
    try {
      ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Connectivity initialization error: $e');
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  // Update connection status
  void _updateConnectionStatus(ConnectivityResult result) {
    connectionType.value = result;

    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        isConnected.value = true;
        _onConnected();
        break;
      case ConnectivityResult.none:
        isConnected.value = false;
        _onDisconnected();
        break;
      default:
        isConnected.value = false;
        break;
    }
  }

  // When connected to internet
  void _onConnected() {
    print('📶 Connected to internet');
    Get.snackbar(
      'Online',
      'Internet connection restored',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
    );

    // Trigger sync when connected
    _triggerSync();
  }

  // When disconnected from internet
  void _onDisconnected() {
    print('📵 Disconnected from internet');
    Get.snackbar(
      'Offline',
      'Working in offline mode',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
    );
  }

  // Trigger data synchronization
  void _triggerSync() {
    // This will be implemented in sync service
    print('🔄 Triggering data sync...');
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

  // Check if connected
  bool get hasConnection => isConnected.value;

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
