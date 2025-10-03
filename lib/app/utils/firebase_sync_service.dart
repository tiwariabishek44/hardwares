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

          // Convert the remote order to local format with new data model
          Map<String, dynamic> localOrderData =
              _convertToLocalFormat(remoteOrder);

          // Insert into local database - now with better error handling
          int insertResult =
              await _dbHelper.insertOrderFromSync(localOrderData);

          if (insertResult > 0) {
            newCount++;
            log('✅ Saved new order with bill code $billCode to local database (ID: $insertResult)');
          } else {
            log('⚠️ Order with bill code $billCode may already exist, skipped');
            skippedCount++;
          }
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
  // Updated _fetchRemoteOrders method with multiple solutions
  Future<List<Map<String, dynamic>>> _fetchRemoteOrders(
      String plumberId) async {
    try {
      // SOLUTION 1: Remove orderBy to avoid index requirement (Quickest fix)
      // This will still filter by plumber_id but won't order by created_at
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('plumber_id', isEqualTo: plumberId)
          .get();

      // Convert to list and sort in memory if needed
      List<Map<String, dynamic>> orders = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by created_at in memory (descending order - newest first)
      orders.sort((a, b) {
        String dateA = a['created_at'] ?? '';
        String dateB = b['created_at'] ?? '';
        return dateB.compareTo(dateA); // Descending order
      });

      return orders;
    } catch (e) {
      log('❌ Error fetching remote orders: $e');
      rethrow;
    }
  }

  // Updated method to convert Firebase order format to local database format
  // Now handles the new data model with proper field mapping
  Map<String, dynamic> _convertToLocalFormat(Map<String, dynamic> remoteOrder) {
    List<dynamic> remoteItems = remoteOrder['items'] ?? [];

    // Process items to ensure they match the new data model structure
    List<Map<String, dynamic>> processedItems = remoteItems.map((item) {
      // Handle both old and new data formats for backward compatibility
      if (item is Map<String, dynamic>) {
        return {
          'uniqueKey': item['uniqueKey'] ?? item['id'] ?? '',
          'itemCode': item['itemCode'] ?? item['item_code'] ?? '',
          'itemName': item['itemName'] ??
              item['name'] ??
              item['nameEnglish'] ??
              'Unknown Item',
          'category': item['category'] ?? '',
          'companyName': item['companyName'] ?? item['company_name'] ?? '',
          'imageUrl': item['imageUrl'] ?? item['image_url'] ?? '',
          'isCompanyItems':
              item['isCompanyItems'] ?? item['isbrandItem'] ?? false,
          'selectedVariantType':
              item['selectedVariantType'] ?? item['variant_type'] ?? '',
          'selectedSize': item['selectedSize'] ?? item['size'] ?? '',
          'rate': _parseToDouble(item['rate'] ?? item['price'] ?? 0.0),
          'quantity': _parseToInt(item['quantity'] ?? 1),
          'dateAdded': item['dateAdded'] ??
              item['created_at'] ??
              DateTime.now().toIso8601String(),
        };
      } else {
        // Handle case where item might be in unexpected format
        log('⚠️ Unexpected item format in Firebase data: $item');
        return {
          'uniqueKey': '',
          'itemCode': '',
          'itemName': 'Unknown Item',
          'category': '',
          'companyName': '',
          'imageUrl': '',
          'isCompanyItems': false,
          'selectedVariantType': '',
          'selectedSize': '',
          'rate': 0.0,
          'quantity': 1,
          'dateAdded': DateTime.now().toIso8601String(),
        };
      }
    }).toList();

    // Calculate totals from processed items
    double calculatedTotal = processedItems.fold(0.0, (sum, item) {
      double rate = _parseToDouble(item['rate']);
      int quantity = _parseToInt(item['quantity']);
      return sum + (rate * quantity);
    });

    // Convert to format expected by local database
    return {
      'bill_code': remoteOrder['bill_code'] ?? '',
      'customer_name': remoteOrder['customer_name'] ?? '',
      'phone_number': remoteOrder['phone_number'] ?? '',
      'plumber_name': remoteOrder['plumber_name'] ?? '',
      'plumber_id': remoteOrder['plumber_id'] ?? '',
      'items': jsonEncode(
          processedItems), // Store processed items with new structure
      'total_amount':
          calculatedTotal, // Use calculated total instead of relying on remote
      'total_items': processedItems.length,
      'created_at':
          remoteOrder['created_at'] ?? DateTime.now().toIso8601String(),
      'synced': 1, // Mark as synced since it came from Firebase
      'firebase_id': remoteOrder['bill_code'] ?? '',
    };
  }

  // Helper method to safely parse double values
  double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to safely parse int values
  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  // Upload unsynced local orders to Firebase
  Future<SyncResult> uploadLocalOrders() async {
    try {
      log('🔄 Starting upload of local orders to Firebase');

      // Get unsynced orders from local database
      List<Map<String, dynamic>> unsyncedOrders =
          await _dbHelper.getUnsyncedOrders();
      log('📤 Found ${unsyncedOrders.length} unsynced orders to upload');

      if (unsyncedOrders.isEmpty) {
        return SyncResult(success: true, added: 0, updated: 0, skipped: 0);
      }

      int uploadedCount = 0;
      int failedCount = 0;

      for (var localOrder in unsyncedOrders) {
        try {
          String billCode = localOrder['bill_code'] ?? '';
          if (billCode.isEmpty) {
            log('⚠️ Skipping order without bill_code');
            failedCount++;
            continue;
          }

          // Convert local order to Firebase format
          Map<String, dynamic> firebaseOrderData =
              _convertToFirebaseFormat(localOrder);

          // Upload to Firebase using bill code as document ID
          await _firestore
              .collection(_collectionName)
              .doc(billCode)
              .set(firebaseOrderData);

          // Mark as synced in local database
          await _dbHelper.markOrderAsSynced(localOrder['id']);
          uploadedCount++;

          log('✅ Uploaded order with bill code $billCode to Firebase');
        } catch (e) {
          log('❌ Failed to upload order: $e');
          failedCount++;
        }
      }

      log('📊 Upload complete. Uploaded: $uploadedCount, Failed: $failedCount');
      return SyncResult(
          success: true,
          added: uploadedCount,
          updated: 0,
          skipped: failedCount);
    } catch (e) {
      log('❌ Error uploading local orders: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  // Convert local database format to Firebase format
  Map<String, dynamic> _convertToFirebaseFormat(
      Map<String, dynamic> localOrder) {
    // Parse items from JSON string
    List<dynamic> items = [];
    try {
      if (localOrder['items'] is String) {
        items = jsonDecode(localOrder['items']);
      } else if (localOrder['items'] is List) {
        items = localOrder['items'];
      }
    } catch (e) {
      log('⚠️ Error parsing items JSON: $e');
      items = [];
    }

    return {
      'bill_code': localOrder['bill_code'] ?? '',
      'customer_name': localOrder['customer_name'] ?? '',
      'phone_number': localOrder['phone_number'] ?? '',
      'plumber_id': localOrder['plumber_id'] ?? '',
      'plumber_name': localOrder['plumber_name'] ?? '',
      'items': items, // Items stored as array in Firebase
      'total_amount': _parseToDouble(localOrder['total_amount']),
      'total_quantity': items.fold(
          0, (sum, item) => sum + _parseToInt(item['quantity'] ?? 1)),
      'total_items': items.length,
      'created_at':
          localOrder['created_at'] ?? DateTime.now().toIso8601String(),
      'synced_at': DateTime.now().toIso8601String(),
      'source': 'mobile_app',
      'app_version': '1.0.0',
    };
  }

  // Perform bidirectional sync (download from Firebase + upload to Firebase)
  Future<SyncResult> performFullSync(String plumberId) async {
    try {
      log('🔄 Starting full bidirectional sync for plumber: $plumberId');

      // First, upload unsynced local orders
      SyncResult uploadResult = await uploadLocalOrders();
      log('📤 Upload result: $uploadResult');

      // Then, download new orders from Firebase
      SyncResult downloadResult = await syncCustomerRequirements(plumberId);
      log('📥 Download result: $downloadResult');

      // Combine results
      return SyncResult(
        success: uploadResult.success && downloadResult.success,
        added: downloadResult.added,
        updated: downloadResult.updated + uploadResult.added,
        skipped: downloadResult.skipped + uploadResult.skipped,
      );
    } catch (e) {
      log('❌ Error during full sync: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }
}

// Class to hold sync result information
class SyncResult {
  final bool success;
  final int added;
  final int updated;
  final int skipped;
  final String? error;

  SyncResult({
    required this.success,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.error,
  });

  @override
  String toString() {
    if (!success) {
      return 'Sync failed: $error';
    }
    return 'Sync successful: Added $added, Updated $updated, Skipped $skipped orders';
  }
}
