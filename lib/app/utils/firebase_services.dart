import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'customer_requirement_list';

  // Updated saveRequirementListToFirebase method for new data model
  Future<String> saveRequirementListToFirebase({
    required String billCode,
    required String customerName,
    required String phoneNumber,
    required String plumberId,
    required String plumberName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Calculate totals using the new data model
      double totalAmount = 0.0;
      int totalQuantity = 0;

      for (var item in items) {
        // Use 'rate' field from the new data model
        double rate = (item['rate'] ?? 0.0) as double;
        int quantity = (item['quantity'] ?? 1) as int;
        totalAmount += rate * quantity;
        totalQuantity += quantity;
      }

      // Process items for Firebase storage with new data model
      List<Map<String, dynamic>> processedItems = items.map((item) {
        return {
          'uniqueKey': item['uniqueKey'] ?? '',
          'itemCode': item['itemCode'] ?? '',
          'itemName': item['itemName'] ?? '',
          'category': item['category'] ?? '',
          'companyName': item['companyName'] ?? '',
          'imageUrl': item['imageUrl'] ?? '',
          'isCompanyItems': item['isCompanyItems'] ?? false,
          'selectedVariantType': item['selectedVariantType'] ?? '',
          'selectedSize': item['selectedSize'] ?? '',
          'rate': item['rate'] ?? 0.0,
          'quantity': item['quantity'] ?? 1,
          'dateAdded': item['dateAdded'] ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      // Create order data using the new data structure
      Map<String, dynamic> orderData = {
        'bill_code': billCode,
        'customer_name': customerName,
        'phone_number': phoneNumber,
        'plumber_id': plumberId,
        'plumber_name': plumberName,
        'items': processedItems,
        'total_amount': totalAmount,
        'total_quantity': totalQuantity,
        'total_items': items.length,
        'created_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'source': 'mobile_app',
        'app_version': '1.0.0', // Add app version for tracking
      };

      // Use bill code as Firebase document ID for consistency
      await _firestore.collection(_collectionName).doc(billCode).set(orderData);

      log('✅ Order saved to Firebase with Bill Code: $billCode');
      log('   - Customer: $customerName');
      log('   - Items: ${items.length}');
      log('   - Total Amount: $totalAmount');
      log('   - Total Quantity: $totalQuantity');

      return billCode;
    } catch (e) {
      log('❌ Error saving order to Firebase: $e');
      rethrow;
    }
  }

  // Get order from Firebase by bill code
  Future<Map<String, dynamic>?> getOrderByBillCode(String billCode) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(billCode).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        log('✅ Retrieved order from Firebase: $billCode');
        return data;
      } else {
        log('⚠️ Order not found in Firebase: $billCode');
        return null;
      }
    } catch (e) {
      log('❌ Error getting order by bill code: $e');
      rethrow;
    }
  }

  // Get all orders for a plumber
  Future<List<Map<String, dynamic>>> getOrdersForPlumber(
      String plumberId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('plumber_id', isEqualTo: plumberId)
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> orders = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      log('✅ Retrieved ${orders.length} orders for plumber: $plumberId');
      return orders;
    } catch (e) {
      log('❌ Error getting orders for plumber: $e');
      rethrow;
    }
  }

  // Get orders by date range
  Future<List<Map<String, dynamic>>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? plumberId,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      // Add plumber filter if provided
      if (plumberId != null) {
        query = query.where('plumber_id', isEqualTo: plumberId);
      }

      // Add date range filter
      query = query
          .where('created_at',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('created_at', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('created_at', descending: true);

      QuerySnapshot querySnapshot = await query.get();

      List<Map<String, dynamic>> orders = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      log('✅ Retrieved ${orders.length} orders for date range');
      return orders;
    } catch (e) {
      log('❌ Error getting orders by date range: $e');
      rethrow;
    }
  }

  // Update order sync status
  Future<void> updateOrderSyncStatus(String billCode, bool synced) async {
    try {
      await _firestore.collection(_collectionName).doc(billCode).update({
        'synced_at': DateTime.now().toIso8601String(),
        'sync_status': synced,
      });

      log('✅ Updated sync status for order: $billCode');
    } catch (e) {
      log('❌ Error updating order sync status: $e');
      rethrow;
    }
  }
}
