import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hardwares/app/modules/login/login_controller.dart';
import 'package:hardwares/app/utils/database_helper.dart';
import 'package:hardwares/app/utils/firebase_services.dart';

class BillsController extends GetxController {
  // Observable variables - Only SQLite data
  final RxBool _isLoading = true.obs; // Changed to true initially
  final RxBool _isRefreshing = false.obs;
  final RxBool _isOnline = true.obs;
  final RxSet<int> _syncingOrders = <int>{}.obs;

  final RxList<Map<String, dynamic>> _orders = <Map<String, dynamic>>[].obs;

  // Services
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final LoginController _loginController = Get.find<LoginController>();

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get isOnline => _isOnline.value;
  bool get isEmpty => _orders.isEmpty;

  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get unsyncedOrders =>
      _orders.where((order) => (order['synced'] ?? 0) == 0).toList();
  List<Map<String, dynamic>> get syncedOrders =>
      _orders.where((order) => (order['synced'] ?? 0) == 1).toList();

  int get totalOrders => _orders.length;
  int get totalUnsyncedOrders => unsyncedOrders.length;
  int get totalSyncedOrders => syncedOrders.length;

  // Check if specific order is syncing/uploading
  bool isOrderSyncing(int orderId) => _syncingOrders.contains(orderId);
  bool isOrderUploading(int orderId) => _syncingOrders.contains(orderId);
  bool get hasSyncingOrders => _syncingOrders.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    log('🔄 BillsController onInit() called');
    _initializeController();
  }

  @override
  void onReady() {
    super.onReady();
    log('🔄 BillsController onReady() called');
    // Force refresh when controller is ready
    Future.delayed(Duration(milliseconds: 100), () {
      refreshOrders();
    });
  }

  // Initialize controller - FIXED
  Future<void> _initializeController() async {
    try {
      log('🔄 Initializing BillsController...');
      _isLoading.value = true;

      await _checkConnectivity();
      _setupConnectivityListener();
      await loadAllOrders();

      log('✅ BillsController initialized successfully - ${_orders.length} orders loaded');
    } catch (e) {
      log('❌ Error initializing BillsController: $e');
      _showErrorSnackbar('Failed to initialize bills');
    } finally {
      _isLoading.value = false;
    }
  }

  // Load all orders from SQLite only - FIXED
  Future<void> loadAllOrders() async {
    try {
      log('🔄 Loading all orders from SQLite...');

      final orders = await _dbHelper.getAllOrders();
      log('📊 Raw orders from database: ${orders.length}');

      if (orders.isEmpty) {
        log('⚠️  No orders found in database');
        _orders.clear();
        return;
      }

      // Process orders to add parsed items
      final processedOrders = <Map<String, dynamic>>[];

      for (var order in orders) {
        try {
          final processedOrder = Map<String, dynamic>.from(order);

          // Parse items from JSON string
          if (order['items'] != null && order['items'].toString().isNotEmpty) {
            try {
              final items = jsonDecode(order['items']);
              processedOrder['parsed_items'] = items;
              log('✅ Parsed items for order ${order['id']}: ${items.length} items');
            } catch (e) {
              log('❌ Error parsing items for order ${order['id']}: $e');
              processedOrder['parsed_items'] = [];
            }
          } else {
            processedOrder['parsed_items'] = [];
          }

          processedOrders.add(processedOrder);
        } catch (e) {
          log('❌ Error processing order ${order['id']}: $e');
        }
      }

      _orders.assignAll(processedOrders);
      log('✅ Loaded ${processedOrders.length} orders from SQLite successfully');

      // Debug: Log first order
      if (processedOrders.isNotEmpty) {
        final firstOrder = processedOrders.first;
        log('📄 First order details: Customer: ${firstOrder['customer_name']}, Bill Code: ${firstOrder['bill_code']}');
      }
    } catch (e) {
      log('❌ Error loading orders: $e');
      _showErrorSnackbar('Failed to load orders');
      _orders.clear();
    }
  }

  // Refresh orders - FIXED
  Future<void> refreshOrders() async {
    if (_isRefreshing.value) {
      log('⚠️  Already refreshing, skipping...');
      return;
    }

    _isRefreshing.value = true;
    log('🔄 Refreshing orders...');

    try {
      await _checkConnectivity();
      await loadAllOrders();
      _showSuccessSnackbar('Orders refreshed');
      log('✅ Orders refreshed successfully');
    } catch (e) {
      log('❌ Error refreshing orders: $e');
      _showErrorSnackbar('Failed to refresh orders');
    } finally {
      _isRefreshing.value = false;
    }
  }

  // Force reload method - NEW
  Future<void> forceReload() async {
    log('🔄 Force reloading orders...');
    _isLoading.value = true;
    _orders.clear();
    await loadAllOrders();
    _isLoading.value = false;
  }

  // Sync/Upload single order to Firebase
  Future<void> uploadOrderToFirebase(int orderId) async {
    return syncOrderToFirebase(orderId);
  }

  // Sync single order to Firebase
  Future<void> syncOrderToFirebase(int orderId) async {
    if (_syncingOrders.contains(orderId)) {
      log('Order $orderId is already being synced');
      return;
    }

    _syncingOrders.add(orderId);

    try {
      await _checkConnectivity();

      if (!_isOnline.value) {
        _showNoInternetDialog();
        return;
      }

      // Find the order in local list
      final orderIndex = _orders.indexWhere((order) => order['id'] == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found');
      }

      final order = _orders[orderIndex];

      // Parse items from JSON string
      List<Map<String, dynamic>> items = [];
      if (order['items'] != null) {
        try {
          final itemsData = jsonDecode(order['items']);
          items = List<Map<String, dynamic>>.from(itemsData);
        } catch (e) {
          throw Exception('Failed to parse order items');
        }
      }

      log('Syncing order $orderId to Firebase...');

      // Sync to Firebase using the bill code from SQLite
      final firebaseBillCode =
          await _firebaseService.saveRequirementListToFirebase(
        billCode: order['bill_code'],
        customerName: order['customer_name'] ?? '',
        phoneNumber: order['phone_number'] ?? '',
        plumberId: _loginController.getPlumberId(),
        plumberName: _loginController.getUserName(),
        items: items,
      );

      // Mark as synced in SQLite
      await _dbHelper.markOrderAsSynced(orderId);

      // Update local order status
      _orders[orderIndex]['synced'] = 1;
      _orders[orderIndex]['firebase_id'] = firebaseBillCode;
      _orders.refresh();

      _showSyncSuccessDialog(
        order['customer_name'] ?? 'Unknown Customer',
        order['bill_code'],
      );

      log('Order $orderId synced successfully with Bill Code: ${order['bill_code']}');
    } catch (e) {
      log('Error syncing order $orderId: $e');
      _showSyncErrorDialog(e.toString());
    } finally {
      _syncingOrders.remove(orderId);
    }
  }

  // Sync all unsynced orders
  Future<void> syncAllOrders() async {
    final unsyncedOrderIds =
        unsyncedOrders.map((order) => order['id'] as int).toList();

    if (unsyncedOrderIds.isEmpty) {
      _showInfoSnackbar('All orders are already synced');
      return;
    }

    int successCount = 0;
    int failCount = 0;

    for (final orderId in unsyncedOrderIds) {
      if (!_syncingOrders.contains(orderId)) {
        try {
          await syncOrderToFirebase(orderId);
          successCount++;
        } catch (e) {
          failCount++;
          log('Failed to sync order $orderId: $e');
        }
      }
    }

    if (successCount > 0) {
      _showSuccessSnackbar('$successCount orders synced successfully');
    }
    if (failCount > 0) {
      _showErrorSnackbar('$failCount orders failed to sync');
    }
  }

  // Delete order (from SQLite only)
  Future<void> deleteOrder(int orderId) async {
    try {
      await _dbHelper.deleteOrder(orderId);

      final orderIndex = _orders.indexWhere((order) => order['id'] == orderId);
      if (orderIndex != -1) {
        _orders.removeAt(orderIndex);
        _showSuccessSnackbar('Order deleted successfully');
        log('Order $orderId deleted');
      }
    } catch (e) {
      log('Error deleting order $orderId: $e');
      _showErrorSnackbar('Failed to delete order');
    }
  }

  // Connectivity methods
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);

      if (_isOnline.value && _orders.isEmpty) {
        loadAllOrders();
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOffline = !_isOnline.value;

    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        _isOnline.value = true;
        if (wasOffline) {
          _showSuccessSnackbar('Connection restored');
        }
        break;
      case ConnectivityResult.none:
        _isOnline.value = false;
        _showErrorSnackbar('No internet connection');
        break;
      default:
        _isOnline.value = false;
        break;
    }
  }

  // Utility methods
  String getFormattedDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';

    try {
      // Handle different date formats
      DateTime date;
      if (dateString.contains('/')) {
        // Firebase format: "2024/12/13"
        final parts = dateString.split('/');
        date = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } else {
        // ISO format: "2024-12-13T10:30:00.000Z"
        date = DateTime.parse(dateString);
      }

      return '${date.day}-${date.month}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  double getOrderTotal(Map<String, dynamic> order) {
    try {
      final items = order['parsed_items'] ?? order['items'];
      if (items != null && items is List) {
        return items.fold(0.0, (sum, item) {
          final price =
              double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
          final quantity =
              int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          return sum + (price * quantity);
        });
      }
      return double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  int getOrderItemsCount(Map<String, dynamic> order) {
    try {
      final items = order['parsed_items'] ?? order['items'];
      if (items != null && items is List) {
        return items.length;
      }
      return int.tryParse(order['total_items']?.toString() ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Dialog and Snackbar methods
  void _showNoInternetDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red[600], size: 24),
            SizedBox(width: 8),
            Text('No Internet', style: TextStyle(color: Colors.red[600])),
          ],
        ),
        content: Text('Please check your internet connection and try again.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              refreshOrders();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSyncSuccessDialog(String customerName, String billCode) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.green[600], size: 24),
            SizedBox(width: 8),
            Text('Sync Successful', style: TextStyle(color: Colors.green[600])),
          ],
        ),
        content: Text(
          'Order for "$customerName" has been synced successfully.\nBill Code: $billCode',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSyncErrorDialog(String error) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600], size: 24),
            SizedBox(width: 8),
            Text('Sync Failed', style: TextStyle(color: Colors.red[600])),
          ],
        ),
        content:
            Text('Failed to sync order. Please try again.\n\nError: $error'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(Get.context!).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[600],
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[600],
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue[600],
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      margin: EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}
