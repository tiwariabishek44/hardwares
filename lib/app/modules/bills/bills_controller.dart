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
  final RxBool _isLoading = true.obs;
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
  }

  // FIXED: Initialize controller with proper order loading
  Future<void> _initializeController() async {
    try {
      log('🔄 Initializing BillsController...');
      _isLoading.value = true;

      // Add debug info about database
      await _debugDatabaseInfo();

      await _checkConnectivity();
      _setupConnectivityListener();

      // Load orders immediately
      await loadAllOrders();

      log('✅ BillsController initialized successfully - ${_orders.length} orders loaded');
    } catch (e) {
      log('❌ Error initializing BillsController: $e');
      _showErrorSnackbar('Failed to initialize bills');
    } finally {
      _isLoading.value = false;
    }
  }

  // NEW: Debug database info
  Future<void> _debugDatabaseInfo() async {
    try {
      log('🔍 DEBUG: Checking database information...');

      // Check if database exists and has tables
      final db = await _dbHelper.database;
      log('🔍 DEBUG: Database instance obtained: ${db.path}');

      // Check if orders table exists and has data
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='orders'");
      if (result.isEmpty) {
        log('❌ DEBUG: Orders table does not exist!');
        return;
      } else {
        log('✅ DEBUG: Orders table exists');
      }

      // Count orders directly using raw query
      final countResult =
          await db.rawQuery("SELECT COUNT(*) as count FROM orders");
      final count = countResult.first['count'] as int;
      log('🔍 DEBUG: Raw order count from database: $count');

      if (count > 0) {
        // Get first few orders to check structure
        final sampleOrders = await db.rawQuery("SELECT * FROM orders LIMIT 3");
        log('🔍 DEBUG: Sample orders:');
        for (int i = 0; i < sampleOrders.length; i++) {
          final order = sampleOrders[i];
          log('   Order ${i + 1}: ID=${order['id']}, Customer=${order['customer_name']}, BillCode=${order['bill_code']}');
        }
      }
    } catch (e) {
      log('❌ DEBUG: Error checking database: $e');
    }
  }

  // ENHANCED: loadAllOrders with more debugging
  Future<void> loadAllOrders() async {
    try {
      log('🔄 Loading all orders from SQLite...');

      // First check database directly
      await _debugDatabaseInfo();

      final orders = await _dbHelper.getAllOrders();
      log('📊 Raw orders from database via DatabaseHelper: ${orders.length}');

      if (orders.isEmpty) {
        log('⚠️ No orders found in database via DatabaseHelper');

        // Try direct database query as fallback
        try {
          final db = await _dbHelper.database;
          final directOrders =
              await db.query('orders', orderBy: 'created_at DESC');
          log('🔍 DEBUG: Direct query result: ${directOrders.length} orders');

          if (directOrders.isNotEmpty) {
            log('⚠️ DatabaseHelper.getAllOrders() is not working, but direct query works!');
            // Process direct orders
            await _processDirectOrders(directOrders);
            return;
          }
        } catch (e) {
          log('❌ DEBUG: Direct query also failed: $e');
        }

        _orders.clear();
        return;
      }

      // Process orders - the items are already parsed in DatabaseHelper.getAllOrders()
      final processedOrders = <Map<String, dynamic>>[];

      for (var order in orders) {
        try {
          final processedOrder = Map<String, dynamic>.from(order);

          // Items are already parsed in DatabaseHelper, just use them
          processedOrder['parsed_items'] = order['items'] ?? [];

          processedOrders.add(processedOrder);

          // Debug log for first few orders
          if (processedOrders.length <= 3) {
            log('📄 Order ${processedOrders.length}:');
            log('   - ID: ${order['id']}');
            log('   - Customer: ${order['customer_name']}');
            log('   - Bill Code: ${order['bill_code']}');
            log('   - Total Amount: ${order['total_amount']}');
            log('   - Items Count: ${(order['items'] as List?)?.length ?? 0}');
            log('   - Created At: ${order['created_at']}');
          }
        } catch (e) {
          log('❌ Error processing order ${order['id']}: $e');
        }
      }

      _orders.assignAll(processedOrders);
      log('✅ Loaded ${processedOrders.length} orders from SQLite successfully');

      // Force UI update
      _orders.refresh();
    } catch (e) {
      log('❌ Error loading orders: $e');
      _showErrorSnackbar('Failed to load orders: $e');
      _orders.clear();
    }
  }

  // NEW: Process direct database orders as fallback
  Future<void> _processDirectOrders(
      List<Map<String, dynamic>> directOrders) async {
    try {
      log('🔧 Processing direct database orders...');

      final processedOrders = <Map<String, dynamic>>[];

      for (var order in directOrders) {
        try {
          final processedOrder = Map<String, dynamic>.from(order);

          // Parse items JSON manually
          if (order['items'] != null && order['items'] is String) {
            try {
              final itemsData = jsonDecode(order['items']);
              processedOrder['parsed_items'] = itemsData;
            } catch (e) {
              log('⚠️ Error parsing items for order ${order['id']}: $e');
              processedOrder['parsed_items'] = [];
            }
          } else {
            processedOrder['parsed_items'] = [];
          }

          processedOrders.add(processedOrder);

          log('📄 Processed Order: Customer=${order['customer_name']}, BillCode=${order['bill_code']}');
        } catch (e) {
          log('❌ Error processing direct order ${order['id']}: $e');
        }
      }

      _orders.assignAll(processedOrders);
      log('✅ Processed ${processedOrders.length} direct orders successfully');
      _orders.refresh();
    } catch (e) {
      log('❌ Error processing direct orders: $e');
    }
  }

  // FIXED: Simplified refreshOrders
  Future<void> refreshOrders() async {
    if (_isRefreshing.value) {
      log('⚠️ Already refreshing, skipping...');
      return;
    }

    _isRefreshing.value = true;
    log('🔄 Refreshing orders...');

    try {
      await _checkConnectivity();
      await loadAllOrders();

      if (_orders.isNotEmpty) {
        _showSuccessSnackbar(
            'Orders refreshed - ${_orders.length} bills found');
      } else {
        log('⚠️ No orders found after refresh');
        _showInfoSnackbar('No bills found');
      }
      log('✅ Orders refreshed successfully');
    } catch (e) {
      log('❌ Error refreshing orders: $e');
      _showErrorSnackbar('Failed to refresh orders');
    } finally {
      _isRefreshing.value = false;
    }
  }

  // FIXED: Force reload method
  Future<void> forceReload() async {
    log('🔄 Force reloading orders...');
    _isLoading.value = true;
    _orders.clear();

    try {
      await loadAllOrders();
    } finally {
      _isLoading.value = false;
    }
  }

  // Add method to manually trigger database check
  Future<void> debugCheckDatabase() async {
    log('🔍 Manual database check triggered...');
    await _debugDatabaseInfo();
    await loadAllOrders();
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

      // Get items - they should already be parsed
      List<Map<String, dynamic>> items = [];
      if (order['parsed_items'] != null && order['parsed_items'] is List) {
        items = List<Map<String, dynamic>>.from(order['parsed_items']);
      } else if (order['items'] != null) {
        // Fallback: try to parse items if they're still in JSON format
        try {
          if (order['items'] is String) {
            final itemsData = jsonDecode(order['items']);
            items = List<Map<String, dynamic>>.from(itemsData);
          } else if (order['items'] is List) {
            items = List<Map<String, dynamic>>.from(order['items']);
          }
        } catch (e) {
          log('❌ Error parsing items for sync: $e');
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

  // FIXED: Update getOrderTotal to use 'rate' field from new data model
  double getOrderTotal(Map<String, dynamic> order) {
    try {
      // First check if we have total_amount directly
      if (order['total_amount'] != null) {
        return double.tryParse(order['total_amount'].toString()) ?? 0.0;
      }

      // Calculate from items using NEW data model fields
      final items = order['parsed_items'] ?? order['items'];
      if (items != null && items is List) {
        return items.fold(0.0, (sum, item) {
          // Use 'rate' field from new data model (not 'price')
          final rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;
          final quantity =
              int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          return sum + (rate * quantity);
        });
      }

      return 0.0;
    } catch (e) {
      log('Error calculating order total: $e');
      return 0.0;
    }
  }

  // FIXED: Update getOrderItemsCount to handle new data model
  int getOrderItemsCount(Map<String, dynamic> order) {
    try {
      // First check if we have total_items directly
      if (order['total_items'] != null) {
        return int.tryParse(order['total_items'].toString()) ?? 0;
      }

      // Count from parsed items
      final items = order['parsed_items'] ?? order['items'];
      if (items != null && items is List) {
        return items.length;
      }

      return 0;
    } catch (e) {
      log('Error getting items count: $e');
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
