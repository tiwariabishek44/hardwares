import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/utils/database_helper.dart';
import 'package:hardwares/app/utils/local_notificaiton.dart';

class EnhancedFirebaseSyncService extends GetxController {
  static final EnhancedFirebaseSyncService _instance =
      EnhancedFirebaseSyncService._internal();
  factory EnhancedFirebaseSyncService() => _instance;
  EnhancedFirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  // Observable variables for sync status
  var isSyncing = false.obs;
  var syncProgress = 0.0.obs;
  var currentSyncOperation = ''.obs;
  var totalItemsToSync = 0.obs;
  var syncedItemsCount = 0.obs;

  // Collection names
  final String _ordersCollection = 'customer_requirement_list';
  final String _partiesCollection = 'parties';
  final String _transactionsCollection = 'transactions';

  @override
  void onInit() {
    super.onInit();
    _notificationService.initialize();
  }

  // Main sync method - uploads all unsynced data
  Future<ComprehensiveSyncResult> uploadAllUnsyncedData(
      String plumberId) async {
    if (isSyncing.value) {
      log('⚠️ Sync already in progress, skipping...');
      return ComprehensiveSyncResult(
          success: false, error: 'Sync already in progress');
    }

    try {
      isSyncing.value = true;
      syncProgress.value = 0.0;
      syncedItemsCount.value = 0;

      log('🔄 Starting comprehensive data upload for plumber: $plumberId');

      // Show initial notification

      // Get counts of unsynced data
      final unsyncedOrders = await _dbHelper.getUnsyncedOrders();
      final unsyncedParties = await _getUnsyncedParties();
      final unsyncedTransactions = await _getUnsyncedTransactions();

      totalItemsToSync.value = unsyncedOrders.length +
          unsyncedParties.length +
          unsyncedTransactions.length;

      if (totalItemsToSync.value == 0) {
        await _notificationService.showNoDataToSyncNotification();
        return ComprehensiveSyncResult(
            success: true, message: 'No data to sync');
      }

      log('📊 Found ${totalItemsToSync.value} items to sync: ${unsyncedOrders.length} orders, ${unsyncedParties.length} parties, ${unsyncedTransactions.length} transactions');

      // Upload data in sequence with progress updates
      final results = ComprehensiveSyncResult(success: true);

      // // 1. Upload Orders
      // if (unsyncedOrders.isNotEmpty) {
      //   currentSyncOperation.value = 'Uploading Items List to server...';
      //   final orderResult = await _uploadOrders(unsyncedOrders, plumberId);
      //   results.ordersResult = orderResult;
      //   await _notificationService.showProgressNotification(
      //       'Orders', orderResult.uploaded, orderResult.failed);
      // }

      // 2. Upload Parties
      if (unsyncedParties.isNotEmpty) {
        currentSyncOperation.value = 'Uploading Parties...';
        final partyResult = await _uploadParties(unsyncedParties, plumberId);
        results.partiesResult = partyResult;
        await _notificationService.showProgressNotification(
            'Parties', partyResult.uploaded, partyResult.failed);
      }

      // 3. Upload Transactions
      if (unsyncedTransactions.isNotEmpty) {
        currentSyncOperation.value = 'Uploading Transactions...';
        final transactionResult =
            await _uploadTransactions(unsyncedTransactions, plumberId);
        results.transactionsResult = transactionResult;
        await _notificationService.showProgressNotification('Transactions',
            transactionResult.uploaded, transactionResult.failed);
      }

      // Show completion notification
      // await _notificationService.showSyncCompleteNotification(results);

      log('✅ Comprehensive sync completed successfully');
      return results;
    } catch (e) {
      log('❌ Error during comprehensive sync: $e');
      // await _notificationService.showSyncErrorNotification(e.toString());
      return ComprehensiveSyncResult(success: false, error: e.toString());
    } finally {
      isSyncing.value = false;
      syncProgress.value = 0.0;
      currentSyncOperation.value = '';
      syncedItemsCount.value = 0;
    }
  }

  // Upload Orders to Firebase
  Future<SyncResult> _uploadOrders(
      List<Map<String, dynamic>> orders, String plumberId) async {
    int uploaded = 0;
    int failed = 0;

    for (int i = 0; i < orders.length; i++) {
      var order = orders[i];
      try {
        String billCode = order['bill_code'] ?? '';
        if (billCode.isEmpty) {
          failed++;
          continue;
        }

        // Convert to Firebase format
        Map<String, dynamic> firebaseOrder =
            _convertOrderToFirebaseFormat(order);

        // Upload to Firebase
        await _firestore
            .collection(_ordersCollection)
            .doc(billCode)
            .set(firebaseOrder);

        // Mark as synced locally
        await _dbHelper.markOrderAsSynced(order['id']);

        uploaded++;
        syncedItemsCount.value++;

        // Update progress notification

        _updateProgress();

        log('✅ Uploaded order: $billCode');
      } catch (e) {
        log('❌ Failed to upload order ${order['bill_code']}: $e');
        failed++;
      }
    }

    return SyncResult(uploaded: uploaded, failed: failed, type: 'Orders');
  }

  // Upload Parties to Firebase
  Future<SyncResult> _uploadParties(
      List<Map<String, dynamic>> parties, String plumberId) async {
    int uploaded = 0;
    int failed = 0;

    for (var party in parties) {
      try {
        // Convert party to Firebase format
        Map<String, dynamic> firebaseParty = {
          'id': party['id'],
          'name': party['name'],
          'phone': party['phone'],
          'balance': _parseToDouble(party['balance']),
          'party_type': party['party_type'],
          'address': party['address'],
          'plumber_id': plumberId, // Associate with plumber
          'created_at': party['created_at'],
          'updated_at': party['updated_at'],
          'synced_at': DateTime.now().toIso8601String(),
        };

        // Upload to Firebase using unique document ID
        String docId = '${plumberId}_party_${party['id']}';
        await _firestore
            .collection(_partiesCollection)
            .doc(docId)
            .set(firebaseParty);

        // Mark as synced locally
        await _markPartyAsSynced(party['id']);
        uploaded++;
        syncedItemsCount.value++;

        log('✅ Uploaded party: ${party['name']} (${party['phone']})');
      } catch (e) {
        log('❌ Failed to upload party ${party['name']}: $e');
        failed++;
      }
    }

    return SyncResult(uploaded: uploaded, failed: failed, type: 'Parties');
  }

  // Upload Transactions to Firebase
  Future<SyncResult> _uploadTransactions(
      List<Map<String, dynamic>> transactions, String plumberId) async {
    int uploaded = 0;
    int failed = 0;

    for (var transaction in transactions) {
      try {
        // Convert transaction to Firebase format
        Map<String, dynamic> firebaseTransaction = {
          'id': transaction['id'],
          'party_id': transaction['party_id'],
          'amount': _parseToDouble(transaction['amount']),
          'transaction_type': transaction['transaction_type'],
          'description': transaction['description'],
          'date': transaction['date'],
          'plumber_id': plumberId, // Associate with plumber
          'created_at': transaction['created_at'],
          'synced_at': DateTime.now().toIso8601String(),
        };

        // Upload to Firebase using unique document ID
        String docId = '${plumberId}_transaction_${transaction['id']}';
        await _firestore
            .collection(_transactionsCollection)
            .doc(docId)
            .set(firebaseTransaction);

        // Mark as synced (or track differently since no synced column)
        await _markTransactionAsSynced(transaction['id']);
        uploaded++;
        syncedItemsCount.value++;

        log('✅ Uploaded transaction: ${transaction['transaction_type']} - ${transaction['amount']}');
      } catch (e) {
        log('❌ Failed to upload transaction ${transaction['id']}: $e');
        failed++;
      }
    }

    return SyncResult(uploaded: uploaded, failed: failed, type: 'Transactions');
  }

  // Helper Methods
  Future<List<Map<String, dynamic>>> _getUnsyncedParties() async {
    return await _dbHelper.getUnsyncedParties();
  }

  Future<List<Map<String, dynamic>>> _getUnsyncedTransactions() async {
    return await _dbHelper.getUnsyncedTransactions();
  }

  Future<void> _markPartyAsSynced(int partyId) async {
    await _dbHelper.markPartyAsSynced(partyId);
  }

  Future<void> _markTransactionAsSynced(int transactionId) async {
    // Since transactions table doesn't have synced columns, we can't mark them
    // Option: Delete after successful upload or keep for local history
    log('Transaction uploaded successfully (ID: $transactionId)');
  }

  Map<String, dynamic> _convertOrderToFirebaseFormat(
      Map<String, dynamic> order) {
    List<dynamic> items = [];
    try {
      if (order['items'] is String) {
        items = jsonDecode(order['items']);
      } else if (order['items'] is List) {
        items = order['items'];
      }
    } catch (e) {
      items = [];
    }

    return {
      'bill_code': order['bill_code'],
      'customer_name': order['customer_name'],
      'phone_number': order['phone_number'],
      'plumber_id': order['plumber_id'],
      'plumber_name': order['plumber_name'],
      'items': items,
      'total_amount': _parseToDouble(order['total_amount']),
      'total_quantity': items.fold(
          0, (sum, item) => sum + _parseToInt(item['quantity'] ?? 1)),
      'total_items': items.length,
      'created_at': order['created_at'],
      'synced_at': DateTime.now().toIso8601String(),
      'source': 'mobile_app',
      'app_version': '1.0.0',
    };
  }

  void _updateProgress() {
    if (totalItemsToSync.value > 0) {
      syncProgress.value = syncedItemsCount.value / totalItemsToSync.value;
    }
  }

  double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }
}

// Result Classes
class ComprehensiveSyncResult {
  final bool success;
  final String? error;
  final String? message;
  SyncResult? ordersResult;
  SyncResult? partiesResult;
  SyncResult? transactionsResult;

  ComprehensiveSyncResult({
    required this.success,
    this.error,
    this.message,
    this.ordersResult,
    this.partiesResult,
    this.transactionsResult,
  });

  int get totalUploaded =>
      (ordersResult?.uploaded ?? 0) +
      (partiesResult?.uploaded ?? 0) +
      (transactionsResult?.uploaded ?? 0);

  int get totalFailed =>
      (ordersResult?.failed ?? 0) +
      (partiesResult?.failed ?? 0) +
      (transactionsResult?.failed ?? 0);
}

class SyncResult {
  final int uploaded;
  final int failed;
  final String type;

  SyncResult({
    required this.uploaded,
    required this.failed,
    required this.type,
  });
}
