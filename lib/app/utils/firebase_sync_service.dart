import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hardwares/app/utils/database_helper.dart';
import 'package:intl/intl.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String _collectionName = 'customer_requirement_list';

  // Main sync function to call during login
  Future<SyncResult> syncCustomerRequirements(String plumberId) async {
    try {
      log('🔄 Starting customer requirements sync for plumber: $plumberId');

      // Fetch requirements from Firebase for this plumber
      List<Map<String, dynamic>> remoteOrders =
          await _fetchRemoteOrders(plumberId);
      log('📥 Fetched ${remoteOrders.length} orders from Firebase');

      // Get existing local orders
      List<Map<String, dynamic>> localOrders = await _dbHelper.getAllOrders();
      log('💾 Found ${localOrders.length} existing local orders');

      // Process and save the orders
      int newCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;

      for (var remoteOrder in remoteOrders) {
        try {
          String billCode = remoteOrder['bill_code'] ?? '';
          if (billCode.isEmpty) {
            log('⚠️ Skipping order without bill_code: ${remoteOrder['id']}');
            skippedCount++;
            continue;
          }

          // Check if order already exists locally by bill code
          bool orderExists = localOrders
              .any((localOrder) => localOrder['bill_code'] == billCode);

          if (orderExists) {
            // Skip existing orders to avoid duplicates
            log('➡️ Order with bill code $billCode already exists locally, skipping');
            skippedCount++;
            continue;
          }

          // Convert the remote order to local format
          Map<String, dynamic> localOrderData =
              _convertToLocalFormat(remoteOrder);

          // Insert into local database
          await _dbHelper.insertOrderFromSync(localOrderData);
          newCount++;
          log('✅ Saved new order with bill code $billCode to local database');
        } catch (e) {
          log('❌ Error processing remote order: $e');
          skippedCount++;
        }
      }

      log('📊 Sync complete. Added: $newCount, Updated: $updatedCount, Skipped: $skippedCount');
      return SyncResult(
          success: true,
          added: newCount,
          updated: updatedCount,
          skipped: skippedCount);
    } catch (e) {
      log('❌ Error syncing customer requirements: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  // Fetch orders from Firebase
  Future<List<Map<String, dynamic>>> _fetchRemoteOrders(
      String plumberId) async {
    try {
      // Query the customer_requirement_list collection for this plumber's orders
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('plumber_id', isEqualTo: plumberId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      log('❌ Error fetching remote orders: $e');
      rethrow;
    }
  }

  // Convert Firebase order format to local database format
  Map<String, dynamic> _convertToLocalFormat(Map<String, dynamic> remoteOrder) {
    List<dynamic> remoteItems = remoteOrder['items'] ?? [];

    // Convert to format expected by local database
    return {
      'bill_code': remoteOrder['bill_code'] ?? '',
      'customer_name': remoteOrder['customer_name'] ?? '',
      'phone_number': remoteOrder['phone_number'] ?? '',
      'plumber_name': remoteOrder['plumber_name'] ?? '',
      'plumber_id': remoteOrder['plumber_id'] ?? '',
      'items': jsonEncode(remoteItems),
      'total_amount': remoteOrder['total_amount'] ?? 0.0,
      'total_items': remoteOrder['total_items'] ?? remoteItems.length,
      'created_at':
          remoteOrder['created_at'] ?? DateTime.now().toIso8601String(),
      'synced': 1, // Mark as synced since it came from Firebase
      'firebase_id': remoteOrder['bill_code'] ?? '',
    };
  }
}

// Class to hold sync result information
class SyncResult {
  final bool success;
  final int added;
  final int updated;
  final int skipped;
  final String? error;

  SyncResult(
      {required this.success,
      this.added = 0,
      this.updated = 0,
      this.skipped = 0,
      this.error});

  @override
  String toString() {
    if (!success) {
      return 'Sync failed: $error';
    }
    return 'Sync successful: Added $added, Updated $updated, Skipped $skipped orders';
  }
}
